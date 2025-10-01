### LOADING THE MODULES
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import f1_score
import matplotlib.pyplot as plt
from itertools import chain

import pandas as pd
import numpy as np
import cebra
import math
import os

### SETTING THE VARIABLES
sub_list = ['sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-05',
            'sub-06', 'sub-07', 'sub-08', 'sub-09', 'sub-10']

train_eeg_list = []
train_val_list = []

for sub in sub_list:
    tmp_csv = pd.read_csv(f"./dataset/{sub}-norm-CEBRA.csv")
    tmp_eeg = tmp_csv.iloc[:, 2:21].to_numpy()
    tmp_val = tmp_csv.iloc[:, 0].to_numpy()
    
    train_eeg_list.append(tmp_eeg)
    train_val_list.append(tmp_val)

### PART I. CEBRA TRAINING
# I-1. fit and save the model
"""
# In our analysis, we used the following code to train the CEBRA model
tmp_model = cebra.CEBRA(batch_size = 2048,        
                         model_architecture = 'offset10-model',   
                         num_hidden_units = 95,
                         learning_rate = .005,              
                         output_dimension = 7,         
                         max_iterations = 2000,
                         max_adapt_iterations = 50,
                         temperature_mode = 'auto',
                         device = 'cuda',
                         hybrid = False,
                         verbose = True)
tmp_model.fit(train_eeg_list, train_val_list)   
tmp_model.save('dim-7_multi-ses_cebra_model.pt') 
"""

# NOTE: for replication, please use our pre-trained model!
tmp_model = cebra.CEBRA.load('dim-7_multi-ses_cebra_model.pt')

# I-2. extracting the embeddings and their length
emb_list = []

for idx in range(len(sub_list)):
    tmp_emb = tmp_model.transform(train_eeg_list[idx], session_id = idx)
    emb_list.append(tmp_emb)

duration_list = []

for idx in range(len(sub_list)):
    length = emb_list[idx].shape[0]
    duration_list.append(length)

### PART II. DECODING ANALYSIS
for idx in range(len(sub_list)):
    test_emb = emb_list[idx]
    test_val = train_val_list[idx]
    
    train_emb = [arr for i, arr in enumerate(emb_list) if i != idx]
    train_val = [arr for i, arr in enumerate(train_val_list) if i != idx]
    
    concat_train_emb = np.vstack(train_emb)
    concat_train_val = np.hstack(train_val)
    
    opt_k_sq = math.sqrt(concat_train_emb.shape[0])
    opt_k_odd = round(opt_k_sq)
    
    if opt_k_odd % 2 == 0:
        opt_k_odd +=1 if opt_k_odd < opt_k_sq else -1
    
    decoder = KNeighborsClassifier(n_neighbors = opt_k_odd)
    decoder.fit(concat_train_emb, concat_train_val)
    probs = decoder.predict_proba(test_emb)
    print(f1_score(decoder.predict(test_emb), test_val, average = 'weighted'))

    df_probs = pd.DataFrame(probs, columns=['neutral', 'positive', 'negative'])
    df_probs.to_csv(f"./results/sub-{idx+1}-decoded-matrix-full.csv", index = False)