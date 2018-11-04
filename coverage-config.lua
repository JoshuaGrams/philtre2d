return {
	module = 'lib.luacov.runner',
	config = {
		runreport = true,
		deletestats = true,
		exclude = {
			"^main",
			"^lib/*",
			"^test/*"
		}
	}
}
