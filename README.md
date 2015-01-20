## How to use

~~~
$ ./check-jmx-jolokia.rb -u http://127.0.0.1:8778 -m "java.lang:type=Memory" -a "HeapMemoryUsage" -i used -k value -w 10 -c -100
CheckJmxJolokia CRITICAL: HeapMemoryUsage used value => 31215760
~~~
