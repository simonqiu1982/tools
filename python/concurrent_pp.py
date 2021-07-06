'''
Created on 2021年6月29日

@author: qiuxiaofan
'''
import time
import requests


import concurrent.futures


def single_param_method(keyword):
    payload = {'wd': keyword}
    r  = requests.get('http://www.baidu.com/s', params=payload)
    print(r.url)
    
def multipal_params_method(keyword, encoding):
    payload = {'wd': keyword,"ie":encoding}
    r  = requests.get('http://www.baidu.com/s', params=payload)
    print(r.url)

#多进程执行，方法只有一个入参时，放到list组装
def single_param(count):
    loop=range(count)
    with concurrent.futures.ProcessPoolExecutor(max_workers=2) as executor:
        chunksize, extra = divmod(len(loop), executor._max_workers * 1)
        array = ['视频' for i in loop]
        for num, result in zip(loop, executor.map(single_param_method, array, chunksize=chunksize)):
            print(num)
        executor.shutdown()
        
#多进程执行，方法只有多个入参时，入参放到tuple，每个tuple放到list
def multipal_params(count):
    loop=range(count)
    with concurrent.futures.ProcessPoolExecutor(max_workers=2) as executor:
        chunksize, extra = divmod(len(loop), executor._max_workers * 1)
        array = [('视频','utf-8') for i in loop]
        for num, result in zip(loop, executor.map(multipal_params_method, *zip(*array), chunksize=chunksize)):
            print(num)
        executor.shutdown()
    
if __name__ == '__main__':
    start_time = time.time()
    single_param(11)
    print ("Thread pool execution in " + str(time.time() - start_time), "seconds")
