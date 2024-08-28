#!/usr/bin/env python3

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--probe_blast', required=True, help='Results of probe sequence blast to reference genome, specified in blast 6 format, one hit per locus')
parser.add_argument('--assembly_blast', required=True, help='Results of assembly scaffold blast to reference genome, specified in blast 6 format')

args = parser.parse_args()

# qseqid                sseqid          pident  length  mismatch    gapopen qstart  qend    sstart      send        evalue  bitscore
# L100__lampyridae_R    NW_022170509.1  100.000 738     0           0       1       738     21766757    21767494    0.0     1363
with open(args.probe_blast, 'r') as f:
    probes = {}
    for line in f.readlines():
        qseqid, sseqid, pident, length, mismatch, gapopen, qstart, qend, sstart, send, evalue, bitscore = line.strip().split('\t')
        if sstart > send:
            direction = 0
        else:
            direction = 1
        probes[qseqid] = {'start': sstart, 'end': send, 'direction': direction}

with open(args.assembly_blast, 'r') as f:
    scaffolds = {}
    for line in f.readlines():
        qseqid, sseqid, pident, length, mismatch, gapopen, qstart, qend, sstart, send, evalue, bitscore = line.strip().split('\t')
        if sstart > send:
            direction = 0
        else:
            direction = 1 
        scaffolds[qseqid] = {'locus': qseqid.split(':')[0], 'start': sstart, 'end': send, 'direction': direction}

keep = set()
for probe, probe_values in probes.items():
    scaffolds_eval = {key: value for key, value in scaffolds.items() if value['locus'] == probe}
    for scaffold, scaffold_values in scaffolds_eval.items():
        if probe_values['direction'] == scaffold_values['direction']:
            scaffold_min = min(scaffold_values['start'], scaffold_values['end'])
            scaffold_max = max(scaffold_values['start'], scaffold_values['end'])
            probe_min = min(probe_values['start'], probe_values['end'])
            probe_max = max(probe_values['start'], probe_values['end'])
            if scaffold_min <= probe_max or scaffold_max >= probe_min:
                keep.add(scaffold)

print(scaffold)

for scaffold in keep: print(scaffold)
