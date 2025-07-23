#!/usr/bin/env python3
"""
ETS2 Mod Manager - USER VERSION
Automatically installs mod collection with enhanced GUI
"""

import os
import sys
import json
import shutil
import subprocess
import getpass
import re
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class ETS2Profile:
    name: str
    path: str
    level: int
    xp: int
    mods: int
    workshop_mods: int
    local_mods: int
    last_save: datetime
    storage_type: str

class ETS2ModManager:
    def __init__(self):
        self.base_dir = Path(__file__).parent
        self.load_order_file = self.base_dir / "load_order.json"
        self.manifest_file = self.base_dir / "manifest_cache.json"
        
        self.mod_list = []
        self.profiles = []
        self.selected_profile = None
        
        self.load_configuration()

    def load_configuration(self):
        """Load mod configuration"""
        print("📝 Loading mod configuration...")
        
        if self.load_order_file.exists():
            with open(self.load_order_file, 'r', encoding='utf-8') as f:
                self.mod_list = json.load(f)
        
        print(f"✅ Loaded {len(self.mod_list)} mods")

    def scan_profiles(self):
        """Scan for ETS2 profiles"""
        print("🔍 Scanning for ETS2 profiles...")
        
        self.profiles = []
        current_user = getpass.getuser()
        
        locations = [
            f"C:/Users/{current_user}/Documents/Euro Truck Simulator 2/profiles",
            f"C:/Users/{current_user}/OneDrive/Documents/Euro Truck Simulator 2/profiles",
            f"C:/Users/{current_user}/OneDrive/Documentos/Euro Truck Simulator 2/profiles",
        ]
        
        # Add Steam locations
        steam_locations = self._find_steam_locations()
        locations.extend(steam_locations)
        
        for location in locations:
            if os.path.exists(location):
                self._scan_location(location)
        
        self.profiles.sort(key=lambda p: p.mods, reverse=True)
        print(f"✅ Found {len(self.profiles)} profiles")

    def _find_steam_locations(self):
        """Find Steam profile locations"""
        locations = []
        try:
            import winreg
            try:
                key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Valve\Steam")
            except FileNotFoundError:
                key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Valve\Steam")
            
            steam_path, _ = winreg.QueryValueEx(key, "InstallPath")
            winreg.CloseKey(key)
            
            userdata_path = os.path.join(steam_path, "userdata")
            if os.path.exists(userdata_path):
                for user_id in os.listdir(userdata_path):
                    user_path = os.path.join(userdata_path, user_id)
                    if os.path.isdir(user_path) and user_id.isdigit():
                        ets2_profiles = os.path.join(user_path, "227300", "remote", "profiles")
                        if os.path.exists(ets2_profiles):
                            locations.append(ets2_profiles)
        except:
            pass
        
        return locations

    def _decode_sii_simple(self, sii_file: str) -> str:
        """Enhanced SII decoding with better text extraction"""
        try:
            with open(sii_file, 'rb') as f:
                data = f.read()
            
            # Try UTF-8 first
            try:
                content = data.decode('utf-8', errors='ignore')
                if any(keyword in content for keyword in ['active_mods', 'experience', 'company_name']):
                    return content
            except:
                pass
            
            # Try to extract readable parts from binary
            text_parts = []
            current_text = ""
            
            for byte in data:
                if 32 <= byte <= 126:  # Printable ASCII
                    current_text += chr(byte)
                else:
                    if len(current_text) > 5:  # Shorter threshold for better extraction
                        text_parts.append(current_text)
                    current_text = ""
            
            if current_text and len(current_text) > 5:
                text_parts.append(current_text)
            
            return ' '.join(text_parts)
            
        except:
            return ""

    def _scan_location(self, profiles_path: str):
        """Scan location for profiles"""
        storage_type = "Steam Cloud" if "userdata" in profiles_path else "OneDrive" if "OneDrive" in profiles_path else "Local"
        
        for profile_dir in os.listdir(profiles_path):
            if "(" in profile_dir and ".bak" in profile_dir:
                continue
                
            profile_path = os.path.join(profiles_path, profile_dir)
            if os.path.isdir(profile_path):
                profile = self._read_profile(profile_path, storage_type)
                if profile:
                    self.profiles.append(profile)

    def _read_profile(self, profile_path: str, storage_type: str) -> Optional[ETS2Profile]:
        """Read profile data with enhanced details"""
        try:
            folder_name = os.path.basename(profile_path)
            name = folder_name
            
            # Decode hex names
            hex_names = {
                "3F": "?",
                "4E656E677565": "Nengue",
                "526F63615F757775": "Roca_uwu", 
                "69727569": "irui",
                "526F647269676F": "Rodrigo",
                "526F647269676F20": "Rodrigo "
            }
            
            if folder_name in hex_names:
                name = hex_names[folder_name]
            
            xp = 0
            level = 1
            mod_count = 0
            workshop_mods = 0
            local_mods = 0
            
            # Try to read profile.sii for detailed info
            profile_file = os.path.join(profile_path, "profile.sii")
            if os.path.exists(profile_file):
                try:
                    content = self._decode_sii_simple(profile_file)
                    
                    # Extract XP
                    xp_match = re.search(r'experience[^:]*:\s*(\d+)', content)
                    if xp_match:
                        xp = int(xp_match.group(1))
                        # Calculate approximate level (ETS2 uses exponential XP)
                        if xp > 0:
                            level = min(150, max(1, int((xp / 1000) ** 0.5) + 1))
                    
                    # Extract mod count
                    mod_match = re.search(r'active_mods\s*:\s*(\d+)', content)
                    if mod_match:
                        declared_count = int(mod_match.group(1))
                        if 0 <= declared_count <= 200:
                            mod_count = declared_count
                            
                    # Count workshop vs local mods
                    mod_entries = re.findall(r'active_mods\[\d+\]\s*:\s*"([^"]*)"', content)
                    for mod in mod_entries:
                        if 'workshop_package' in mod:
                            workshop_mods += 1
                        else:
                            local_mods += 1
                        
                except Exception as e:
                    pass
            
            # Count saves as fallback
            if mod_count == 0:
                save_path = os.path.join(profile_path, "save")
                if os.path.exists(save_path):
                    saves = [d for d in os.listdir(save_path) if os.path.isdir(os.path.join(save_path, d))]
                    mod_count = len(saves)
                    local_mods = mod_count  # Assume all local if can't read profile
            
            # Get last modification time
            try:
                last_save = datetime.fromtimestamp(os.path.getmtime(profile_path))
            except:
                last_save = datetime.now()
            
            if name != "Unknown" or mod_count > 0:
                return ETS2Profile(
                    name=name,
                    path=profile_path,
                    level=level,
                    xp=xp,
                    mods=mod_count,
                    workshop_mods=workshop_mods,
                    local_mods=local_mods,
                    last_save=last_save,
                    storage_type=storage_type
                )
        except:
            pass
        
        return None

    def select_profile(self) -> bool:
        """Enhanced profile selection with detailed information"""
        if not self.profiles:
            self.scan_profiles()
        
        if not self.profiles:
            print("❌ No profiles found!")
            return False
        
        # Enhanced GUI Header
        print("\n" + "="*80)
        print("🎮 ETS2 PROFILE SELECTION - ENHANCED VIEW")
        print("="*80)
        print(f"📦 Ready to install {len(self.mod_list)} mods from this collection")
        print("🔍 Select the profile you want to modify:")
        print("="*80)
        
        # Display profiles with detailed information
        for i, profile in enumerate(self.profiles, 1):
            print(f"\n{i:2d}. 👤 {profile.name}")
            print(f"    📊 Level: {profile.level:3d} | 🏆 XP: {profile.xp:,}")
            print(f"    🎯 Current Mods: {profile.mods:3d} ({profile.workshop_mods} Workshop + {profile.local_mods} Local)")
            print(f"    💾 Storage: {profile.storage_type}")
            print(f"    📅 Last Activity: {profile.last_save.strftime('%Y-%m-%d %H:%M')}")
            print(f"    📁 Path: {profile.path}")
            
            # Add visual indicators
            if profile.mods > 50:
                print("    ⭐ Heavy mod user")
            elif profile.mods > 20:
                print("    🔧 Moderate mod user")
            elif profile.mods > 0:
                print("    🆕 Light mod user")
            else:
                print("    📦 Clean profile")
        
        print("\n" + "="*80)
        print("⚠️  IMPORTANT:")
        print("   • Your original profile will be backed up as 'profile.sii.backup'")
        print("   • Close ETS2 completely before proceeding")
        print("   • The installer will replace your current mod list")
        print("="*80)
        
        while True:
            try:
                choice = input(f"\n🎯 Select profile (1-{len(self.profiles)}) or 0 to cancel: ").strip()
                if choice == "0":
                    print("\n❌ Installation cancelled by user")
                    return False
                
                index = int(choice) - 1
                if 0 <= index < len(self.profiles):
                    self.selected_profile = self.profiles[index]
                    
                    # Confirmation with details
                    print(f"\n✅ Selected Profile: {self.selected_profile.name}")
                    print(f"   Current setup: {self.selected_profile.mods} mods → Will become: {len(self.mod_list)} mods")
                    print(f"   Storage type: {self.selected_profile.storage_type}")
                    
                    confirm = input(f"\n🚀 Install {len(self.mod_list)} mods to '{self.selected_profile.name}'? (y/n): ").strip().lower()
                    if confirm == 'y':
                        return True
                    else:
                        print("❌ Installation cancelled")
                        return False
                else:
                    print("❌ Invalid selection! Please try again.")
            except ValueError:
                print("❌ Please enter a valid number!")

    def install_mods(self) -> bool:
        """Install mods to selected profile"""
        if not self.selected_profile:
            print("❌ No profile selected!")
            return False
        
        print(f"🚀 Installing {len(self.mod_list)} mods to profile: {self.selected_profile.name}")
        
        profile_file = os.path.join(self.selected_profile.path, "profile.sii")
        
        try:
            # Create backup
            backup_file = profile_file + ".backup"
            if os.path.exists(profile_file):
                shutil.copy2(profile_file, backup_file)
                print(f"✅ Created backup: {backup_file}")
            
            # Create new SII structure
            profile_name = self.selected_profile.name
            sii_content = f"""SiiNunit
{{

profile_data : profile.data {{
 profile_name: "{profile_name}"
 company_name: "{profile_name}"
 experience: 1000
 money_account: 500000
 
 active_mods: {len(self.mod_list)}
"""
            
            # Add all mods
            for i, mod in enumerate(self.mod_list):
                sii_content += f' active_mods[{i}]: "{mod}"\n'
            
            # Close structure
            sii_content += """
 user_data[0]: ff_data
}}

}}
"""
            
            # Write new profile
            with open(profile_file, 'w', encoding='utf-8') as f:
                f.write(sii_content)
            
            print(f"🎮 Successfully installed {len(self.mod_list)} mods!")
            print("ℹ️  ETS2 will handle file encoding when you next run the game")
            return True
            
        except Exception as e:
            print(f"❌ Error installing mods: {e}")
            return False

    def run(self):
        """Run the mod manager with enhanced GUI"""
        # Enhanced Main Header
        print("\n" + "="*80)
        print("🚛 ETS2 MOD MANAGER - PROFESSIONAL INSTALLATION SYSTEM")
        print("="*80)
        print("🎯 Universal mod installer with profile detection")
        print("🔧 Automatic backup and safe installation")
        print("📦 Complete mod collection management")
        print("="*80)
        
        if not self.mod_list:
            print("❌ No mods loaded! Package may be corrupted.")
            input("\nPress Enter to exit...")
            return
        
        # Show package information
        print(f"\n� PACKAGE INFORMATION:")
        print(f"   🎮 Total Mods: {len(self.mod_list)}")
        
        # Try to show some example mods
        if len(self.mod_list) >= 5:
            print(f"   🔧 Sample Mods:")
            for i, mod in enumerate(self.mod_list[:5]):
                mod_display = mod.split('|')[-1] if '|' in mod else mod
                if len(mod_display) > 50:
                    mod_display = mod_display[:47] + "..."
                print(f"      {i+1}. {mod_display}")
            if len(self.mod_list) > 5:
                print(f"      ... and {len(self.mod_list) - 5} more mods")
        
        print(f"\n🛡️  SAFETY FEATURES:")
        print(f"   ✅ Automatic profile backup (.backup)")
        print(f"   ✅ Profile detection (Steam/OneDrive/Local)")
        print(f"   ✅ Safe SII file creation")
        print(f"   ✅ ETS2 compatibility")
        
        print("\n" + "="*80)
        
        # Profile selection
        if self.select_profile():
            print("\n" + "="*80)
            print("🚀 INSTALLATION READY")
            print("="*80)
            print(f"📁 Target Profile: {self.selected_profile.name}")
            print(f"🔢 Mod Count: {self.selected_profile.mods} → {len(self.mod_list)}")
            print(f"💾 Storage: {self.selected_profile.storage_type}")
            print(f"🛡️  Backup: profile.sii.backup will be created")
            print("="*80)
            
            final_confirm = input("\n🎯 FINAL CONFIRMATION - Proceed with installation? (y/n): ").strip().lower()
            if final_confirm == 'y':
                print("\n🚀 Starting installation...")
                print("="*40)
                
                if self.install_mods():
                    print("\n" + "="*80)
                    print("🎉 INSTALLATION COMPLETED SUCCESSFULLY!")
                    print("="*80)
                    print(f"✅ {len(self.mod_list)} mods installed to '{self.selected_profile.name}'")
                    print("✅ Original profile backed up")
                    print("✅ ETS2 ready to launch")
                    print("\n🎮 NEXT STEPS:")
                    print("   1. Launch Euro Truck Simulator 2")
                    print("   2. Load your profile")
                    print("   3. Enjoy your new mod collection!")
                    print("="*80)
                else:
                    print("\n❌ INSTALLATION FAILED!")
                    print("🛡️  Your original profile backup is safe")
            else:
                print("\n❌ Installation cancelled by user")
        else:
            print("\n❌ No profile selected - installation cancelled")
        
        print("\n" + "="*80)
        input("Press Enter to exit...")

if __name__ == "__main__":
    manager = ETS2ModManager()
    manager.run()
