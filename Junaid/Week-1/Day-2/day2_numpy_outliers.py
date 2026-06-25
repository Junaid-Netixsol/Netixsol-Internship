import numpy as np
from numpy.lib.stride_tricks import sliding_window_view

def rolling_means(arr, size_of_window):
    windows = sliding_window_view(arr, size_of_window)
    means = [0] * len(windows)
    for i, window in enumerate(windows):
        means[i] = np.mean(window)
    return means

def find_zscores(arr):
    mean = np.mean(arr)
    std = np.std(arr)
    z_scores = (arr - mean) / std
    return z_scores

def total_outliers(zscored_arr):
    return np.sum(zscored_arr > 2)

def main():
    rng = np.random.default_rng()
    arr = rng.normal(loc=10, scale=30, size=100)
    means = rolling_means(arr, 5) # rolling statistics
    z_scores = find_zscores(arr) # calculate z-score
    total_outliers_ = total_outliers(z_scores) # find the number of outliers
    print(f"Rolling Means: {means}")
    print(f"Z-Scores: {z_scores}")
    print(f"Total Outliers: {total_outliers_}")


main()