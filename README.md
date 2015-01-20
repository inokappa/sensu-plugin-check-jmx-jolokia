## example jolokia response

~~~
$ curl -s http://127.0.0.1:8778/jolokia/read/java.lang:type=Memory/HeapMemoryUsage/used | jq .
{
  "timestamp": 1421741614,
  "status": 200,
  "request": {
    "mbean": "java.lang:type=Memory",
    "path": "used",
    "attribute": "HeapMemoryUsage",
    "type": "read"
  },
  "value": 31944064
}
~~~

## how to use

~~~
$ ./check-jmx-jolokia.rb -u http://127.0.0.1:8778 -m "java.lang:type=Memory" -a "HeapMemoryUsage" -i used -k value -w 10 -c -100
CheckJmxJolokia CRITICAL: HeapMemoryUsage used value => 31215760
~~~
