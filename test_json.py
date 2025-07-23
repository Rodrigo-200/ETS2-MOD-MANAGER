#!/usr/bin/env python3
"""
Simple test script to debug the JSON loading issue
"""

import os
import json
import sys

print("Python version:", sys.version)
print("Current directory:", os.getcwd())

try:
    base_dir = os.path.dirname(os.path.abspath(__file__))
    load_order_file = os.path.join(base_dir, "load_order.json")
    
    print("Base dir:", base_dir)
    print("Load order file:", load_order_file)
    print("File exists:", os.path.exists(load_order_file))
    
    if os.path.exists(load_order_file):
        with open(load_order_file, 'r', encoding='utf-8') as f:
            mod_list = json.load(f)
        print("✅ Successfully loaded", len(mod_list), "mods")
        print("First mod:", mod_list[0] if mod_list else "None")
        print("Last mod:", mod_list[-1] if mod_list else "None")
    else:
        print("❌ File not found!")
        
except Exception as e:
    print("❌ Error:", e)
    import traceback
    traceback.print_exc()
