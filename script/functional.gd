extends Node

var thread_count = 0
var threads = []

func _init():
	for i in thread_count:
		threads.append(Thread.new())
