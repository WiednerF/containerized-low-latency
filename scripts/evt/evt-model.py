import os
import csv
import json
import sympy
import argparse
import subprocess
import pandas as pd
import numpy as np
from collections import defaultdict
from evt.dataset import Dataset
from evt.methods.peaks_over_threshold import PeaksOverThreshold
from scipy.stats import pareto, norm
from evt.estimators.gpdmle import GPDMLE


def calculate_limit_of_return_level(this_tail, this_scale, pot_part, threshold):
    full_return_period2 = sympy.symbols('full_return_period2')

    rl_pt0 = this_scale/this_tail
    rl_pt1 = (full_return_period2*pot_part)**(this_tail) - 1.0
    return_level = threshold + rl_pt0 * rl_pt1

    r = sympy.limit(return_level, full_return_period2, sympy.oo)
    return r.evalf()

def run_evt_analysis2(flow_data, threshold_percentile, input_file):
    evt_results_all = []
    metrics = ['latency']
    evt_part = 0.2
    eval_part = 1 - evt_part
    for m in metrics:
        evt_data = flow_data[m][:int(len(flow_data[m])*evt_part)]
        eval_data = flow_data[m][int(len(flow_data[m])*evt_part):]
        
        to_df = []
        for elem in evt_data:
            to_df.append([elem, 'evt'])
        for elem in eval_data:
            to_df.append([elem, 'eval'])
        df = pd.DataFrame(to_df, columns=['latency', 'dataset'])
        
        threshold = np.percentile(evt_data, threshold_percentile)
        threshold_idx = 0
        ts = pd.Series(evt_data)
        ts = ts.sample(frac=1).reset_index(drop=True)
        dataset = Dataset(ts)

        evt_percentiles_pot = []
        evt_data_pot = [elem for elem in evt_data if elem > threshold]
        if len(evt_data_pot) == 0:
            continue
        
        start = time.time()
        peaks_over_threshold = PeaksOverThreshold(dataset, threshold)
        stop = time.time()
        pos_time = stop - start
        num_pot_datapoints = len(peaks_over_threshold.series_tail)
        start = time.time()
        mle = GPDMLE(peaks_over_threshold)
        tail_estimate, scale_estimate = mle.estimate()
        stop = time.time()
        mle_time = stop - start
        fig, ax = plt.subplots()
        mle.plot_qq_gpd(ax)
        fig.tight_layout()
        plt.savefig(f'{input_file}.mle.pdf')
        
        
        eval_data_percentile_pot = [elem for elem in eval_data[:np.min([len(eval_data), int((float(len(eval_data))))])] if elem > threshold]
        full_return_period = len(eval_data)
        pot_part = float(num_pot_datapoints) / float(len(evt_data))
        exceedances = {}
        return_levels = {}
        this_tail = float(tail_estimate.estimate)
        this_scale = float(scale_estimate.estimate)
        rl_pt0 = this_scale/this_tail
        rl_pt1 = (full_return_period*pot_part)**this_tail - 1.0
        return_level = threshold + rl_pt0 * rl_pt1
        exceedance = []
        for elem_idx, elem in enumerate(eval_data_percentile_pot):
            if elem > return_level:
                exceedance.append([elem_idx, elem])
        exceedances = exceedance
        return_levels = return_level
        
        
        if this_tail < 0:
            return_level_convergence = calculate_limit_of_return_level(this_tail, this_scale, pot_part, threshold)
        else:
            return_level_convergence = float('inf')

        single_res = {
                    'metric': m,
                    'threshold': float(threshold),
                    'threshold_percentile': float(threshold_percentile),
                    'tail_estimate': float(this_tail),
                    'scale_estimate': float(this_scale),
                    'num_exceedances': len(exceedances),
                    'exceedances': exceedances,
                    'return_levels': float(return_levels),
                    'return_level_convergence': float(return_level_convergence),
                }
        evt_results_all.append(single_res)
            
    return evt_results_all

def run_multiple(filename):
    evt_part = 0.2
    eval_part = 1 - evt_part

    to_unzip = filename
    subprocess.run(["unzstd", to_unzip, "-o", to_unzip.replace('.zst', '')])

    input_file = to_unzip.replace('.zst', '')

    flows = defaultdict(list)
    latency_tmp = []
    ts_sorted = []

    if os.stat(input_file).st_size < 230:
        return (filename, 1)
    with open(input_file) as f:
        reader = csv.reader(f)
        headers = next(reader, None)
        for row in reader:
            latency_tmp.append(float(row[0]))
            ts_sorted.append([float(row[0]), int(row[1])])

        ts_sorted.sort(key=lambda x: x[1])
        flows['latency'] = [elem[0] for elem in ts_sorted]

        print(f"Total data points: {len(flows['latency'])}")
        print(f"EVT data points: {len(flows['latency'])*evt_part}")
        print(f"Eval data points: {len(flows['latency'])*eval_part}")

        flat_list = run_evt_analysis2(flows, 99.95, input_file)
        with open(f'{input_file}.evt.json', 'w+', encoding='utf-8') as g:
            json.dump(flat_list[0], g, ensure_ascii=False, indent=4)
    return (filename, 0)


def main(args):
    run_multiple(args.data)

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument("--data", type=str, help="EVT CSV file with latency timestamps")
    args = p.parse_args()
    main(args)
