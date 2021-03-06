package vscode.testadapter.api;

typedef TestController = {
	/**
		Register the given Test Adapter. The Test Controller should subscribe to the `adapter.tests`
		event source immediately in order to receive the test definitions.
	**/
	function registerTestAdapter(adapter:TestAdapter):Void;
	function unregisterTestAdapter(adapter:TestAdapter):Void;
}
