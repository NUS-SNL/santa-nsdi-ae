from datetime import datetime, time
import multiprocessing
from time import sleep

DAY_START = time(12,3)
DAY_END=time(12,5)

def run_child():
	while 1:
		print("1-ongoing sub process")
		sleep(5)
		current_time = datetime.now().time()
		print(current_time)

def run_parent():
		print("2-start parent process")
		cur_time=datetime.now().time()
		print(cur_time)
		child_process = None
		flag=0;
		while flag ==0:
				current_time = datetime.now().time()
				running = False
		
				if DAY_START <= current_time <= DAY_END:
						running = True
		
				if running and child_process is None:
						print("3-start sub process")
						child_process = multiprocessing.Process(target = run_child)
						child_process.start()
						print("4-sub process start success")
				
				if not running and child_process is not None:
						print("5-close sub process")
						child_process.terminate()
						child_process.join()
						child_process = None
						flag=1
						print("6- sub process close success")
						#cur=time.time()
						#cur1_ms=int(round(cur*1000))
						#char_cur1_ms=str(cur1_ms)
#						fa = open("/home/cirlab/test2.txt","a")
#						fa.write("\n hello ")
#						fa.write(str(current_time))
						fa.write("6- sub process close success")
#						fa.flush()
#						fa.close()
			
				fa = open("/home/cirlab/data2.txt","a")
				fa.write("\n hello ")
				fa.write(str(current_time))
				fa.flush()
				sleep(5)

if __name__ == '__main__':
	run_parent()
