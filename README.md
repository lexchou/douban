这个脚本包含两部分：

1. crawler.pl 用来抓取豆瓣上的帖子
2. main.pl 用来启动FastCGI进程，这个进程不需要手动执行，附带了一个./debug脚本用来进入调试模式，调试模式下检测到文件变动会自动重启main.pl

# 搭建方法：
1. 使用CPAN安装以下perl的依赖：
  * CGI::Fast
  * DBI
  * Date::Parse
  * JSON
  * LWP::UserAgent
  * List::MoreUtils
  * YAML::XS
2. 安装spawn-fcgi，MySQL。
3. 在MySQL里建好数据库douban，然后导入database.sql的内容
4. 将config.yaml-template复制为config.yaml，并修改里面的数据库配置和蜘蛛的HTTP Header
5. 配置nginx：nginx使用的配置：

        location /douban {
            root           html;
            fastcgi_pass   127.0.0.1:8184;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            charset utf-8;
            include        fastcgi_params;
        }
        location /bootstrap {
            alias /Users/lexchou/project/douban/bootstrap-3.3.2-dist;
        }

6. 启动crawler.pl 开始抓取豆瓣的帖子。
7. 启动./debug 跑爬虫的Web后端。


# FAQ 
1. 我搭建好的页面看不到豆瓣的图片
>> 豆瓣的CDN有防盗链检测，为了绕过这一检测，你需要配置HTTPS服务，可以申请自签名的证书或者从StartSSL申请免费的SSL
2. 如何启用管理员模式
>> 管理员模式可以删不要的广告贴或者看不惯的内容，方法是在浏览器的开发人员控制台里输入：
>> document.cookie = 'key=asdf'
>> key的配置在config.yaml的removeKey李
3. 如何添加新小组
>> 往groups表里插入数据即可
4. 有些小组需要加入后才可以抓取，如何让蜘蛛可以抓到
>> 先用你豆瓣账号登陆，然后把你的Cookie放到config.yaml的headers里去然后重启crawler
5. 为什么只抓小组第一页的内容
>> 因为尺度大的绝不会跑到第二页去，都是直接给删了
6. 有其他类似的蜘蛛没
>> 有， https://f.binux.me/haixiuzu.html，这也是个豆瓣爬虫，不过有好多不需要的内容也不能查看原帖所以自己重做了一个，用了它的几行css



