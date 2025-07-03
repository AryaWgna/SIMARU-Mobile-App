#!/bin/bash

# This script finds print statements and dart:developer logs in the Flutter codebase

echo "Searching for print statements in lib directory..."
grep -r "print(" --include="*.dart" lib/

echo -e "\nSearching for dart:developer logs in lib directory..."
grep -r "developer.log" --include="*.dart" lib/

echo -e "\nSummary:"
echo "Print statements found: $(grep -r "print(" --include="*.dart" lib/ | wc -l)"
echo "Developer logs found: $(grep -r "developer.log" --include="*.dart" lib/ | wc -l)"
echo "Total logs to replace: $(($(grep -r "print(" --include="*.dart" lib/ | wc -l) + $(grep -r "developer.log" --include="*.dart" lib/ | wc -l)))"

echo -e "\nFiles with the most print statements:"
grep -r "print(" --include="*.dart" lib/ | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -10

echo -e "\nFiles with the most developer logs:"
grep -r "developer.log" --include="*.dart" lib/ | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -10 