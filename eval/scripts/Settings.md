{\rtf1\ansi\ansicpg1252\cocoartf2708
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Bold;\f1\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red70\green137\blue204;\red24\green24\blue24;\red193\green193\blue193;
\red85\green129\blue224;\red202\green202\blue202;\red194\green126\blue101;\red238\green46\blue56;\red167\green197\blue152;
}
{\*\expandedcolortbl;;\cssrgb\c33725\c61176\c83922;\cssrgb\c12157\c12157\c12157;\cssrgb\c80000\c80000\c80000;
\cssrgb\c40392\c58824\c90196;\cssrgb\c83137\c83137\c83137;\cssrgb\c80784\c56863\c47059;\cssrgb\c95686\c27843\c27843;\cssrgb\c70980\c80784\c65882;
}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\b\fs24 \cf2 \cb3 \expnd0\expndtw0\kerning0
\outl0\strokewidth0 \strokec2 ## Settings for 9-flow Experiments
\f1\b0 \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 9 flows\cb1 \
\
\pard\pardeftab720\partightenfactor0
\cf5 \cb3 \strokec5 -\cf4 \strokec4  Exp 1:\cb1 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3     \cf5 \strokec5 -\cf4 \strokec4  9 flows (3 Cubic, 3 BBR, 3 Vegas) start together running for 100s. (Using the result of 20~100s for convergence)\cb1 \
\cb3     \cf5 \strokec5 -\cf4 \strokec4  9 flows (3 Cubic, 3 BBR, 3 Vegas) start every 5s and each runs for 100s, changing the start order of three CCAs. (I used the result of all the period; you can try the result of 50~100s for convergence)\cb1 \
\cb3     \cf5 \strokec5 -\cf4 \strokec4  Testing AQMs including FIFO, CoDel, Santa and Cebinae. \cb1 \
\
\cb3 Drawing the scatter plot of Throughput~Delay, Delay~Loss and Throughput~Loss.\cb1 \
\
\cb3 Link parameters:\cb1 \
\
\cb3 ```py\cb1 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 bottleneck_bw_values = [\cf7 \strokec7 '50Mbps'\cf6 \strokec6 ] \cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6 bottleneck_delay_values = [\cf7 \strokec7 '10ms'\cf6 \strokec6 ] \cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6 switch_total_bdp_values = [\cf7 \strokec7 '10'\cf6 \strokec6 ] \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 ```\cb1 \
\
\cb3 Detailed running command including other parameters:\cb1 \
\
\cb3 ```py\cb1 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6 command = \cf7 \strokec7 './waf --cwd="/home/zyx/santa/ns/" --run "testCCutility --config_path=/home/zyx/santa/ns/configs/testCCutility.json\cf2 \strokec2 \\\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf7 \cb3 \strokec7 --result_dir=tmp_index/testCCutility2/\cf2 \strokec2 \{qdisc\}\cf7 \strokec7 / --enable_debug=1 --logtcp=1 --seed=2022 --run=1205 --sim_seconds=120 --app_seconds_start=1 --app_seconds_end=100\cf2 \strokec2 \\\cf4 \cb1 \strokec4 \
\cf7 \cb3 \strokec7 --tracing_period_us=1000000 --progress_interval_ms=1000 --delackcount=2 --app_packet_size=1440 --bottleneck_bw=\cf2 \strokec2 \{bottleneck_bw\}\cf7 \strokec7  --bottleneck_delay=\cf2 \strokec2 \{bottleneck_delay\}\cf7 \strokec7 \\ \cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf8 \cb3 \strokec8 --\cf6 \strokec6 switch_total_bufsize=\{switch_total_bufsize\} \cf8 \strokec8 --\cf6 \strokec6 vdt=\cf8 \strokec8 1ns\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 dt=\cf8 \strokec8 12ms\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 l=\cf8 \strokec8 10000ns\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 p=\cf9 \strokec9 4\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 tau=\cf9 \strokec9 0.01\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 delta_port=\cf9 \strokec9 0.01\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 delta_flow=\cf9 \strokec9 0.01\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 queuedisc_type=\{qdiscfull\}\\\cf4 \cb1 \strokec4 \
\cf8 \cb3 \strokec8 --\cf6 \strokec6 transport_prot0=\{cca0\} \cf8 \strokec8 --\cf6 \strokec6 transport_prot1=\{cca1\} \cf8 \strokec8 --\cf6 \strokec6 transport_prot2=\{cca2\} \cf8 \strokec8 --\cf6 \strokec6 leaf_bw0=\cf8 \strokec8 1000Mbps\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 leaf_bw1=\cf8 \strokec8 1000Mbps\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 leaf_bw2=\cf8 \strokec8 1000Mbps\cf6 \strokec6 \\ \cf4 \cb1 \strokec4 \
\cf8 \cb3 \strokec8 --\cf6 \strokec6 app_bw0=\cf8 \strokec8 100Mbps\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 app_bw1=\cf8 \strokec8 100Mbps\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 app_bw2=\cf8 \strokec8 100Mbps\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 leaf_delay0=\cf8 \strokec8 10ms\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 leaf_delay1=\cf8 \strokec8 10ms\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 leaf_delay2=\cf8 \strokec8 10ms\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 num_cca=\cf9 \strokec9 3\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 num_cca0=\cf9 \strokec9 3\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 num_cca1=\cf9 \strokec9 3\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 num_cca2=\cf9 \strokec9 3\cf6 \strokec6 \\\cf4 \cb1 \strokec4 \
\cf8 \cb3 \strokec8 --\cf6 \strokec6 probe=\cf8 \strokec8 10s\cf6 \strokec6  \cf8 \strokec8 --\cf6 \strokec6 num_queue=\cf9 \strokec9 4\cf7 \strokec7 "'.format(\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf6 \cb3 \strokec6                             qdisc=qdisc,\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                             qdiscfull=qdiscfull,\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                             cca0=ccas[\cf9 \strokec9 0\cf6 \strokec6 ],\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                             cca1=ccas[\cf9 \strokec9 1\cf6 \strokec6 ],\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                             cca2=ccas[\cf9 \strokec9 2\cf6 \strokec6 ],\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                             bottleneck_bw=bottleneck_bw,\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                             bottleneck_delay=bottleneck_delay,\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                             switch_total_bufsize=switch_total_bufsize\cf4 \cb1 \strokec4 \
\cf6 \cb3 \strokec6                         )\cf4 \cb1 \strokec4 \
\pard\pardeftab720\partightenfactor0
\cf4 \cb3 ```\cb1 \
}