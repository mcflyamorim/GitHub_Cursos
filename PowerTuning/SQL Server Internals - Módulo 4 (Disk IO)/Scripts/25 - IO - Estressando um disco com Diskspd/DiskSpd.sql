----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------



-- 1 - Abrir resource monitor pra ver o uso de disco...

/*
  Parameter	Description
  -b	Block size of the I/O, specified as (K/M/G). For example –b8K means an 8KB block size, which is relevant for SQL Server
  -d	Test duration in seconds. Tests of 30-60 seconds are usually long enough to get valid results
  -o	Outstanding I/Os (meaning queue depth) per target, per worker thread
  -t	Worker threads per test file target
  -h	Disable software caching at the operating system level and hardware write caching, which is a good idea for testing SQL Server
  -r	Random or sequential flag. If –r is used random tests are done, otherwise sequential tests are done
  -w	Write percentage. For example, –w25 means 25% writes, 75% reads
  -Z	Workload test write source buffer size, specified as (K/M/G). Used to supply random data for writes, which is a good idea for SQL Server testing
  -L	Capture latency information during the test, which is a very good idea for testing SQL Server
  -c	Creates workload file(s) of the specified size, specified as (K/M/G)
*/


-- Rodar o comando abaixo no cmd
"%internals4%\Outros\DiskSpd\amd64\diskspd.exe" -b64K -d30 -o4 -t8 -h -r -w25 -L -Z1G -c1G C:\test1.dat
/*
C:\WINDOWS\system32>"%internals4%\Outros\DiskSpd\amd64\diskspd.exe" -b64K -d30 -o4 -t8 -h -r -w25 -L -Z1G -c1G C:\test1.dat

Command Line: D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - M≤dulo 4 (Disk IO)\\Outros\DiskSpd\amd64\diskspd.exe -b64K -d30 -o4 -t8 -h -r -w25 -L -Z1G -c1G C:\test1.dat

Input parameters:

        timespan:   1
        -------------
        duration: 30s
        warm up time: 5s
        cool down time: 0s
        measuring latency
        random seed: 0
        path: 'C:\test1.dat'
                think time: 0ms
                burst size: 0
                software cache disabled
                hardware write cache disabled, writethrough on
                write buffer size: 1073741824
                performing mix test (read/write ratio: 75/25)
                block size: 65536
                using random I/O (alignment: 65536)
                number of outstanding I/O operations: 4
                thread stride size: 0
                threads per file: 8
                using I/O Completion Ports
                IO priority: normal

System information:

        computer name: dellfabiano
        start time: 2020/07/28 20:24:24 UTC

Results for timespan 1:
*******************************************************************************

actual test time:       30.00s
thread count:           8
proc count:             12

CPU |  Usage |  User  |  Kernel |  Idle
-------------------------------------------
   0|  17.66%|   6.82%|   10.83%|  82.34%
   1|  12.08%|   3.65%|    8.44%|  87.92%
   2|  46.46%|   5.16%|   41.30%|  53.54%
   3|  15.52%|   3.59%|   11.93%|  84.48%
   4|  19.11%|   6.67%|   12.45%|  80.89%
   5|  14.27%|   5.05%|    9.22%|  85.73%
   6|  22.40%|   8.18%|   14.22%|  77.60%
   7|  17.24%|   2.97%|   14.27%|  82.76%
   8|  14.74%|   6.98%|    7.76%|  85.26%
   9|   9.48%|   4.01%|    5.47%|  90.52%
  10|  22.50%|  12.45%|   10.05%|  77.50%
  11|  15.78%|   4.95%|   10.83%|  84.22%
-------------------------------------------
avg.|  18.94%|   5.87%|   13.06%|  81.06%

Total IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |      2816344064 |        42974 |      89.53 |    1432.42 |    2.791 |     4.996 | C:\test1.dat (1024MiB)
     1 |      2831220736 |        43201 |      90.00 |    1439.99 |    2.777 |     5.047 | C:\test1.dat (1024MiB)
     2 |      2527068160 |        38560 |      80.33 |    1285.29 |    3.111 |     5.850 | C:\test1.dat (1024MiB)
     3 |      2761818112 |        42142 |      87.79 |    1404.69 |    2.846 |     5.334 | C:\test1.dat (1024MiB)
     4 |      2760835072 |        42127 |      87.76 |    1404.19 |    2.848 |     5.139 | C:\test1.dat (1024MiB)
     5 |      2811297792 |        42897 |      89.37 |    1429.85 |    2.796 |     5.143 | C:\test1.dat (1024MiB)
     6 |      2716270592 |        41447 |      86.35 |    1381.52 |    2.894 |     5.314 | C:\test1.dat (1024MiB)
     7 |      2785542144 |        42504 |      88.55 |    1416.75 |    2.822 |     5.172 | C:\test1.dat (1024MiB)
-----------------------------------------------------------------------------------------------------
total:       22010396672 |       335852 |     699.67 |   11194.71 |    2.857 |     5.248

Read IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |      2107965440 |        32165 |      67.01 |    1072.13 |    3.199 |     5.258 | C:\test1.dat (1024MiB)
     1 |      2126970880 |        32455 |      67.61 |    1081.80 |    3.188 |     5.352 | C:\test1.dat (1024MiB)
     2 |      1899560960 |        28985 |      60.38 |     966.14 |    3.548 |     6.187 | C:\test1.dat (1024MiB)
     3 |      2073755648 |        31643 |      65.92 |    1054.73 |    3.259 |     5.579 | C:\test1.dat (1024MiB)
     4 |      2071330816 |        31606 |      65.84 |    1053.50 |    3.259 |     5.427 | C:\test1.dat (1024MiB)
     5 |      2102001664 |        32074 |      66.82 |    1069.10 |    3.227 |     5.458 | C:\test1.dat (1024MiB)
     6 |      2033975296 |        31036 |      64.66 |    1034.50 |    3.318 |     5.600 | C:\test1.dat (1024MiB)
     7 |      2086993920 |        31845 |      66.34 |    1061.47 |    3.232 |     5.429 | C:\test1.dat (1024MiB)
-----------------------------------------------------------------------------------------------------
total:       16502554624 |       251809 |     524.59 |    8393.37 |    3.275 |     5.535

Write IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |       708378624 |        10809 |      22.52 |     360.29 |    1.579 |     3.874 | C:\test1.dat (1024MiB)
     1 |       704249856 |        10746 |      22.39 |     358.19 |    1.536 |     3.719 | C:\test1.dat (1024MiB)
     2 |       627507200 |         9575 |      19.95 |     319.16 |    1.789 |     4.429 | C:\test1.dat (1024MiB)
     3 |       688062464 |        10499 |      21.87 |     349.96 |    1.601 |     4.281 | C:\test1.dat (1024MiB)
     4 |       689504256 |        10521 |      21.92 |     350.69 |    1.611 |     3.904 | C:\test1.dat (1024MiB)
     5 |       709296128 |        10823 |      22.55 |     360.76 |    1.522 |     3.795 | C:\test1.dat (1024MiB)
     6 |       682295296 |        10411 |      21.69 |     347.02 |    1.631 |     4.099 | C:\test1.dat (1024MiB)
     7 |       698548224 |        10659 |      22.21 |     355.29 |    1.597 |     4.078 | C:\test1.dat (1024MiB)
-----------------------------------------------------------------------------------------------------
total:        5507842048 |        84043 |     175.08 |    2801.34 |    1.606 |     4.022



total:
  %-ile |  Read (ms) | Write (ms) | Total (ms)
----------------------------------------------
    min |      0.066 |      0.063 |      0.063
   25th |      1.804 |      0.499 |      1.319
   50th |      2.171 |      0.831 |      1.982
   75th |      2.732 |      1.418 |      2.541
   90th |      4.703 |      1.923 |      4.158
   95th |      7.024 |      4.067 |      6.212
   99th |     32.494 |     21.667 |     30.107
3-nines |     65.603 |     50.500 |     63.806
4-nines |     92.938 |     82.385 |     91.315
5-nines |    118.808 |    120.822 |    118.808
6-nines |    127.135 |    120.822 |    127.135
7-nines |    127.135 |    120.822 |    127.135
8-nines |    127.135 |    120.822 |    127.135
9-nines |    127.135 |    120.822 |    127.135
    max |    127.135 |    120.822 |    127.135

C:\WINDOWS\system32>
*/


-- Se eu rodar no pendrive, a performance é incomparável

"%internals4%\Outros\DiskSpd\amd64\diskspd.exe" -b64K -d30 -o4 -t8 -h -r -w25 -L -Z1G -c1G E:\test1.dat

/*
C:\WINDOWS\system32>"%internals4%\Outros\DiskSpd\amd64\diskspd.exe" -b64K -d30 -o4 -t8 -h -r -w25 -L -Z1G -c1G E:\test1.dat

Command Line: D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - M≤dulo 4 (Disk IO)\\Outros\DiskSpd\amd64\diskspd.exe -b64K -d30 -o4 -t8 -h -r -w25 -L -Z1G -c1G E:\test1.dat

Input parameters:

        timespan:   1
        -------------
        duration: 30s
        warm up time: 5s
        cool down time: 0s
        measuring latency
        random seed: 0
        path: 'E:\test1.dat'
                think time: 0ms
                burst size: 0
                software cache disabled
                hardware write cache disabled, writethrough on
                write buffer size: 1073741824
                performing mix test (read/write ratio: 75/25)
                block size: 65536
                using random I/O (alignment: 65536)
                number of outstanding I/O operations: 4
                thread stride size: 0
                threads per file: 8
                using I/O Completion Ports
                IO priority: normal

System information:

        computer name: dellfabiano
        start time: 2020/07/28 20:28:36 UTC

Results for timespan 1:
*******************************************************************************

actual test time:       30.00s
thread count:           8
proc count:             12

CPU |  Usage |  User  |  Kernel |  Idle
-------------------------------------------
   0|  12.02%|   3.80%|    8.22%|  87.98%
   1|   5.36%|   3.12%|    2.24%|  94.64%
   2|  17.07%|   4.22%|   12.86%|  82.93%
   3|  10.72%|   1.61%|    9.11%|  89.28%
   4|  13.33%|   3.44%|    9.89%|  86.67%
   5|   5.99%|   3.90%|    2.08%|  94.01%
   6|  10.52%|   4.63%|    5.88%|  89.48%
   7|   3.23%|   1.09%|    2.13%|  96.77%
   8|   5.94%|   2.08%|    3.85%|  94.06%
   9|   4.79%|   2.65%|    2.13%|  95.21%
  10|  13.95%|  11.71%|    2.24%|  86.05%
  11|   6.15%|   2.19%|    3.96%|  93.85%
-------------------------------------------
avg.|   9.09%|   3.70%|    5.38%|  90.91%

Total IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |        28966912 |          442 |       0.92 |      14.73 |  272.026 |   227.194 | E:\test1.dat (1024MiB)
     1 |        29425664 |          449 |       0.94 |      14.97 |  268.838 |   228.152 | E:\test1.dat (1024MiB)
     2 |        29884416 |          456 |       0.95 |      15.20 |  264.120 |   227.191 | E:\test1.dat (1024MiB)
     3 |        29556736 |          451 |       0.94 |      15.03 |  267.351 |   227.822 | E:\test1.dat (1024MiB)
     4 |        29163520 |          445 |       0.93 |      14.83 |  270.966 |   238.433 | E:\test1.dat (1024MiB)
     5 |        29360128 |          448 |       0.93 |      14.93 |  268.849 |   227.351 | E:\test1.dat (1024MiB)
     6 |        29163520 |          445 |       0.93 |      14.83 |  271.396 |   228.927 | E:\test1.dat (1024MiB)
     7 |        28835840 |          440 |       0.92 |      14.67 |  272.694 |   220.570 | E:\test1.dat (1024MiB)
-----------------------------------------------------------------------------------------------------
total:         234356736 |         3576 |       7.45 |     119.20 |  269.502 |   228.273

Read IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |        21430272 |          327 |       0.68 |      10.90 |  267.271 |   216.368 | E:\test1.dat (1024MiB)
     1 |        21626880 |          330 |       0.69 |      11.00 |  264.193 |   225.842 | E:\test1.dat (1024MiB)
     2 |        21954560 |          335 |       0.70 |      11.17 |  256.924 |   228.502 | E:\test1.dat (1024MiB)
     3 |        21692416 |          331 |       0.69 |      11.03 |  263.420 |   230.411 | E:\test1.dat (1024MiB)
     4 |        22282240 |          340 |       0.71 |      11.33 |  265.988 |   231.206 | E:\test1.dat (1024MiB)
     5 |        21954560 |          335 |       0.70 |      11.17 |  264.729 |   225.137 | E:\test1.dat (1024MiB)
     6 |        21823488 |          333 |       0.69 |      11.10 |  275.699 |   228.005 | E:\test1.dat (1024MiB)
     7 |        22347776 |          341 |       0.71 |      11.37 |  262.340 |   212.519 | E:\test1.dat (1024MiB)
-----------------------------------------------------------------------------------------------------
total:         175112192 |         2672 |       5.57 |      89.06 |  265.056 |   224.889

Write IO
thread |       bytes     |     I/Os     |    MiB/s   |  I/O per s |  AvgLat  | LatStdDev |  file
-----------------------------------------------------------------------------------------------------
     0 |         7536640 |          115 |       0.24 |       3.83 |  285.547 |   254.999 | E:\test1.dat (1024MiB)
     1 |         7798784 |          119 |       0.25 |       3.97 |  281.718 |   233.958 | E:\test1.dat (1024MiB)
     2 |         7929856 |          121 |       0.25 |       4.03 |  284.044 |   222.312 | E:\test1.dat (1024MiB)
     3 |         7864320 |          120 |       0.25 |       4.00 |  278.195 |   220.160 | E:\test1.dat (1024MiB)
     4 |         6881280 |          105 |       0.22 |       3.50 |  287.086 |   259.808 | E:\test1.dat (1024MiB)
     5 |         7405568 |          113 |       0.24 |       3.77 |  281.060 |   233.364 | E:\test1.dat (1024MiB)
     6 |         7340032 |          112 |       0.23 |       3.73 |  258.602 |   231.174 | E:\test1.dat (1024MiB)
     7 |         6488064 |           99 |       0.21 |       3.30 |  308.360 |   242.940 | E:\test1.dat (1024MiB)
-----------------------------------------------------------------------------------------------------
total:          59244544 |          904 |       1.88 |      30.13 |  282.644 |   237.507



total:
  %-ile |  Read (ms) | Write (ms) | Total (ms)
----------------------------------------------
    min |      4.292 |     14.853 |      4.292
   25th |    108.527 |    116.355 |    110.295
   50th |    199.604 |    215.521 |    204.025
   75th |    346.000 |    359.904 |    350.953
   90th |    545.568 |    614.677 |    560.323
   95th |    723.967 |    781.632 |    741.284
   99th |   1116.637 |   1159.714 |   1126.260
3-nines |   1352.586 |   1359.021 |   1352.586
4-nines |   1385.033 |   1359.021 |   1385.033
5-nines |   1385.033 |   1359.021 |   1385.033
6-nines |   1385.033 |   1359.021 |   1385.033
7-nines |   1385.033 |   1359.021 |   1385.033
8-nines |   1385.033 |   1359.021 |   1385.033
9-nines |   1385.033 |   1359.021 |   1385.033
    max |   1385.033 |   1359.021 |   1385.033

C:\WINDOWS\system32>
*/