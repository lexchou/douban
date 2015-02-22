var msnry = new Masonry(document.getElementById('container'), {columnWidth : 20});;
var topics = {};
var removeTopic = function(topic) {
	if(!confirm("确定删除么？"))
		return;
	var n = document.getElementById('to-' + topic);
	if(n) {
		$.ajax({
			url : '/douban/api/' + currentGroup + '/' + topic + '?key=' + removeKey,
			type : 'DELETE',
		}).done(function(ret) {
            if(!ret.success) {
                alert("只有管理员才能删除");
                return;
            }
            msnry.remove(n);
            msnry.layout();
        });
	}
	return false;
};
var open = function(id) {
    var topic = topics[id];
    $('#post_detail .modal-title').text(topic.title);
    $('#post_detail .modal-body').html("正在加载...");
    $.ajax({
        url : '/douban/api/' + currentGroup + '/' + id
    }).done(function(html) {
        $('#post_detail .modal-body').html(html);
    });
    $('#post_detail').modal('show');
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
                topics[topic.id] = topic;
	    		var s = template.replace(/\{(\w+)\}/g, function(_, s) {
	    			if(s == 'timestamp')
	    				return (new Date(topic.timestamp * 1000)).toLocaleString();
                    if(s == 'thumbs')
                        return topic.thumbUrls.map(function(url) { return "<img src='" + url + "'/>";}).join('');
	    			return topic[s];
	    		}).replace(/^\s+|\s+$/gm, '');
	    		var elem = $.parseHTML(s)[0];
                $('img', elem).each(function(idx, img) {
                    img.onload = function() {
                        container.appendChild(elem);
                        msnry.appended(elem);
                    };
                });
	    		elements.push(elem);
	    	});
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
