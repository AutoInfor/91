# -*- coding: utf-8 -*-
import scrapy
from bs4 import BeautifulSoup
from scrapy import Request
from ..items import 91Item
from ..settings import SPIDER_NAME, ROOT_URL, BLOCK_INFO, MAX_PAGES
class 91spiderSpider(scrapy.Spider):
    name = SPIDER_NAME
    root_url = ROOT_URL
    max_pages = MAX_PAGES

    def start_requests(self):
        for key in BLOCK_INFO.keys:
            request_url = str(key) + "1"
            yield Request(url=request_url, callback=self.parse_block_page, meta={'block_name': BLOCK_INFO[key]})

    def parse_block_page(self, response):
        content = response.body
        viewkey=re.findall(r'<a target=blank href="http://9.space/view_video.php\?viewkey=(.*)&page=.*&viewtype=.*?&category=.*?">',content)
        block_name = response.meta['block_name']
        for key in list(set(viewkey)):
            topic_url = base_url+key
            yield Request(url=topic_url, callback=self.parse_poster_page,
                          meta={'block_name': block_name})

        page_num = response_url_list[-1].split('=')[-1]
        if int(page_num) < self.max_pages:
            cur_url = response.url
            num = 0 - len(page_num)
            next_url = cur_url[:num] + str(int(page_num) + 1)
            yield Request(url=next_url, callback=self.parse_block_page, meta={'block_name': block_name}, dont_filter=True)

    def parse_poster_page(self, response):
        content = response.body
        block_name = response.meta['block_name']
        topic_url = response.url
        video_url=re.findall(r'<source src="(.*?)" type=\'video/mp4\'>',content)
        tittle=re.findall(r'<div id="viewvideo-title">(.*?)</div>',content),re.S)
        try:
            t=tittle[0]
            tittle[0]=t.replace('\n','')
            t=tittle[0].replace(' ','')
        except IndexError:
            pass
        fileItem = 91Item()
        fileItem['topic_title'] = tittle
        fileItem['topic_url'] = topic_url
        fileItem['block_name'] = block_name
        fileItem['file_urls'] = str(video_url[0])
        return fileItem




# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://doc.scrapy.org/en/latest/topics/item-pipeline.html
from scrapy import Request
from scrapy.pipelines.files import FilesPipeline

class 91FilePipeline(FilesPipeline):
    def get_media_requests(self, item, info):
        for index, image_url in enumerate(item['file_urls']):
            yield Request(image_url, meta={'name': item['topic_title'], 'index': str(index), 'block_name': item['block_name']})
    def file_path(self, request, response=None, info=None):
        # 因为'/'字符会在路径中转换成文件夹，所以要替换掉
        name = request.meta['name']
        return request.meta['block_name'] + "/" + name +  request.meta['index'] + ".mp4"
