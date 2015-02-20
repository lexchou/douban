
var msnry = new Masonry(document.getElementById('container'), {columnWidth : 10});;
var removeTopic = function(topic) {
	if(!confirm("确定删除么？"))
		return;
	var n = document.getElementById('to-' + topic);
	if(n) {
		msnry.remove(n);
		msnry.layout();
		$.ajax({
			url : '/douban/api/' + currentGroup + '/' + topic + '?key=' + removeKey,
			type : 'DELETE',
		});
	}
	return false;
};

$(function() {
	var lastId = 0;
	var loading = false;

	var loadMore = function() {
		if(loading)
			return;
		loading = true;
	    $.get('/douban/api/' + currentGroup + '?id=' + lastId, function(ret) {
	    	loading = false;
	    	var results = ret.results;
	    	if(!results.length)
	    		return;
	    	var template = document.getElementById('topic').innerText;
	    	var elements = [];
	    	results.forEach(function(topic)
	    	{
	    		var s = template.replace(/\{(\w+)\}/g, function(_, s) {
	    			if(s == 'timestamp')
	    				return (new Date(topic.timestamp * 1000)).toLocaleString();
	    			return topic[s];
	    		}).replace(/^\s+|\s+$/gm, '');
	    		var elem = $.parseHTML(s)[0];
	    		container.appendChild(elem);
	    		elements.push(elem);
	    	});
    		msnry.appended(elements);
	    	lastId = results[results.length - 1].id;
	    });
	};
	loadMore();
	$(window).scroll(function(e) {
		var p = document.body.scrollTop / (document.body.scrollHeight - screen.height);
		if(p > 0.9)
			loadMore();
	});

});