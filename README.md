# Sensu Check JMX Jolokia

This is the updated and improved version of inokappa's [sensu-plugin-check-jmx-jolokia](https://github.com/inokappa/sensu-plugin-check-jmx-jolokia) plugin. This version has been updated to use the new Timeout function introduced in later versions of Sensu. It also allows checking MBeans which return Strings. 
*This plugin requires [Jolokia](https://jolokia.org/) to be running on the host machine, exposing the JMX beans that you want to monitor.

## Install

Put to your sensu plugins directory.

~~~
sudo cp check-jmx-jolokia.rb /etc/sensu/plugins/
sudo chmod 755 /etc/sensu/plugins/check-jmx-jolokia.rb
~~~

## Usage

~~~bash
$ ./check-jmx-jolokia.rb -u http://127.0.0.1:8778 -m "java.lang:type=Memory" -a "HeapMemoryUsage" -i "used" -k "value" -w 10 -c -100
CheckJmxJolokia CRITICAL: HeapMemoryUsage used value => 31215760
~~~

## Example

~~~bash
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
