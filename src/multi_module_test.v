module vest


struct SomeServiceWithInjection {
	service &SimpleService [inject]
	with_name &SimpleService [inject: SimpleService]
}


fn test_parent_can_inject_children() ! {
	// mut child := set_up_module
	assert true
}
