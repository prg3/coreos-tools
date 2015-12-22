#!/usr/bin/python

from string import Template
import json
import os
import subprocess


print "Creating iso cloud drive images from cloud-image.json"

host_data = json.load(open("cloud-init.json"))

hosts = host_data['hosts']
common = host_data['common']

sshString = ""
for key in common['sshkey']:
	sshString += " - %s\n" %(key)

if not os.path.exists("template/openstack/latest"):
	os.makedirs("template/openstack/latest")
	

FNULL = open(os.devnull, 'w')

for host in hosts:
	print "\tCreating for %s"%(host['hostname'])
	fh = open("cloud-init.template",'r')
	s = Template(fh.read())
	fh.close()

	fh = open("template/openstack/latest/user_data",'w')
	newtemplate = s.substitute(
		publicip=host['public_ip'],
		privateip=host['private_ip'],
		hostname=host['hostname'],
		etcd2key=common['etcd2key'],
		region=common['region'],
		sshkey=sshString,
		gateway=common['gateway'],
		network=common['network'],
		dns=common['dns']
	)
	fh.write(newtemplate)
	fh.close()
	# mkisofs -R -V config-2 -o ../configdrive.iso `pwd`
	sp = subprocess.Popen(["mkisofs","-R","-V config-2","-oconfigdrive-%s.iso"%(host['hostname']), "template"], stdin=None, stdout=FNULL, stderr=subprocess.STDOUT)

