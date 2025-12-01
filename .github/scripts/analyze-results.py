#!/usr/bin/env python3
"""
Analyze codespace provisioning results from CSV file.
Computes statistics and identifies outliers.
"""

import csv
import sys
import os
from pathlib import Path
from statistics import mean, stdev
from typing import List, Dict, Tuple

def read_csv_results(csv_path: str) -> List[Dict]:
    """Read CSV file and return list of result dictionaries."""
    results = []
    try:
        with open(csv_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                results.append(row)
    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading CSV file: {e}")
        sys.exit(1)
    
    return results

def parse_time_value(value: str) -> float | None:
    """Parse time value from string, handling N/A."""
    if value == "N/A" or not value:
        return None
    try:
        return float(value)
    except ValueError:
        return None

def compute_statistics(results: List[Dict]) -> Dict:
    """Compute statistics for provisioning times."""
    available_times = []
    postcreate_times = []
    
    for row in results:
        avail_time = parse_time_value(row.get('Available_Time_Sec', ''))
        if avail_time is not None:
            available_times.append(avail_time)
        
        post_time = parse_time_value(row.get('PostCreate_Time_Sec', ''))
        if post_time is not None:
            postcreate_times.append(post_time)
    
    stats = {
        'total_runs': len(results),
        'successful_runs': len(available_times),
        'failed_runs': len(results) - len(available_times)
    }
    
    if available_times:
        stats['available_mean'] = mean(available_times)
        stats['available_min'] = min(available_times)
        stats['available_max'] = max(available_times)
        if len(available_times) > 1:
            stats['available_stdev'] = stdev(available_times)
        else:
            stats['available_stdev'] = 0.0
    
    if postcreate_times:
        stats['postcreate_mean'] = mean(postcreate_times)
        stats['postcreate_min'] = min(postcreate_times)
        stats['postcreate_max'] = max(postcreate_times)
        if len(postcreate_times) > 1:
            stats['postcreate_stdev'] = stdev(postcreate_times)
        else:
            stats['postcreate_stdev'] = 0.0
    
    return stats

def identify_outliers(results: List[Dict], stats: Dict) -> List[Tuple[str, float, str]]:
    """Identify outliers using IQR method (values beyond 1.5 * IQR from Q1/Q3)."""
    outliers = []
    
    if 'available_mean' not in stats or 'available_stdev' not in stats:
        return outliers
    
    # Using 2 standard deviations as threshold for outliers
    threshold = stats['available_mean'] + (2 * stats['available_stdev'])
    
    for row in results:
        avail_time = parse_time_value(row.get('Available_Time_Sec', ''))
        if avail_time is not None and avail_time > threshold:
            outliers.append((
                f"Iteration {row['Iteration']}",
                avail_time,
                f"{row['DevContainer']} on {row['Machine']}"
            ))
    
    return outliers

def format_summary_markdown(results: List[Dict], stats: Dict, outliers: List[Tuple]) -> str:
    """Format analysis results as GitHub markdown summary."""
    md = ["# Codespace Provisioning Analysis", ""]
    
    # Overall statistics
    md.append("## Overall Statistics")
    md.append(f"- **Total Runs**: {stats['total_runs']}")
    md.append(f"- **Successful**: {stats['successful_runs']}")
    md.append(f"- **Failed**: {stats['failed_runs']}")
    md.append("")
    
    # Available time statistics
    if 'available_mean' in stats:
        md.append("## Provisioning Time (Available State)")
        md.append(f"- **Average**: {stats['available_mean']:.2f}s")
        md.append(f"- **Min**: {stats['available_min']:.2f}s")
        md.append(f"- **Max**: {stats['available_max']:.2f}s")
        md.append(f"- **Std Dev**: {stats['available_stdev']:.2f}s")
        md.append("")
    
    # Post-create time statistics
    if 'postcreate_mean' in stats:
        md.append("## Post-Create Time")
        md.append(f"- **Average**: {stats['postcreate_mean']:.2f}s")
        md.append(f"- **Min**: {stats['postcreate_min']:.2f}s")
        md.append(f"- **Max**: {stats['postcreate_max']:.2f}s")
        md.append(f"- **Std Dev**: {stats['postcreate_stdev']:.2f}s")
        md.append("")
    
    # Outliers
    if outliers:
        md.append("## ⚠️ Outliers Detected")
        md.append("Runs that took significantly longer than average:")
        md.append("")
        for name, time, config in outliers:
            md.append(f"- **{name}**: {time:.2f}s ({config})")
        md.append("")
    else:
        md.append("## ✅ No Outliers Detected")
        md.append("All runs completed within expected time range.")
        md.append("")
    
    # Results table
    md.append("## Detailed Results")
    md.append("")
    md.append("| Iteration | DevContainer | Machine | Available Time (s) | Post-Create Time (s) | Timestamp |")
    md.append("|-----------|--------------|---------|-------------------|---------------------|-----------|")
    
    for row in results:
        md.append(f"| {row['Iteration']} | {row['DevContainer']} | {row['Machine']} | "
                 f"{row['Available_Time_Sec']} | {row['PostCreate_Time_Sec']} | {row['Timestamp']} |")
    
    md.append("")
    return "\n".join(md)

def write_github_output(stats: Dict, output_file: str = None):
    """Write key metrics to GitHub Actions output."""
    if output_file is None:
        output_file = os.environ.get('GITHUB_OUTPUT')
    
    if not output_file:
        print("Warning: GITHUB_OUTPUT not set, skipping output file")
        return
    
    try:
        with open(output_file, 'a') as f:
            if 'available_mean' in stats:
                f.write(f"average_provisioning_time={stats['available_mean']:.2f}\n")
                f.write(f"min_provisioning_time={stats['available_min']:.2f}\n")
                f.write(f"max_provisioning_time={stats['available_max']:.2f}\n")
            f.write(f"total_runs={stats['total_runs']}\n")
            f.write(f"successful_runs={stats['successful_runs']}\n")
            f.write(f"failed_runs={stats['failed_runs']}\n")
    except Exception as e:
        print(f"Warning: Failed to write GitHub output: {e}")

def main():
    if len(sys.argv) < 2:
        print("Usage: analyze-results.py <csv_file_path>")
        sys.exit(1)
    
    csv_path = sys.argv[1]
    
    print(f"Analyzing results from: {csv_path}")
    
    # Read and analyze results
    results = read_csv_results(csv_path)
    
    if not results:
        print("No results found in CSV file")
        sys.exit(1)
    
    stats = compute_statistics(results)
    outliers = identify_outliers(results, stats)
    
    # Generate markdown summary
    summary = format_summary_markdown(results, stats, outliers)
    
    # Write to GitHub Step Summary if available
    summary_file = os.environ.get('GITHUB_STEP_SUMMARY')
    if summary_file:
        try:
            with open(summary_file, 'a') as f:
                f.write(summary)
            print(f"Summary written to GitHub Step Summary")
        except Exception as e:
            print(f"Warning: Failed to write step summary: {e}")
    
    # Always print to console
    print("\n" + summary)
    
    # Write outputs for downstream jobs
    write_github_output(stats)
    
    print("\nAnalysis complete!")

if __name__ == "__main__":
    main()
