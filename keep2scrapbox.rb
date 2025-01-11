require 'oga'
require 'json'
require 'time'
require 'pp'

def content_filter(content)
  # content.gsub('[', '\[').gsub(']', '\]')
  content
end

def date_label(date)
  "##{date.strftime('%Y')} ##{date.strftime('%Y/%m')} ##{date.strftime('%m/%d')} ##{date.strftime('%Y/%m/%d')}"
end

pages = []
Dir.glob('Takeout/Keep/*.html').each.with_index(1) do |file, i|
  File.open file do |f|
    html = Oga.parse_html(f.read)

    title = html.css('.title').text # || File.basename(file, '.*')
    contents = html.css('.content').first.children.map {|node| content_filter node.text }.reject(&:empty?)

    chip_weblink = html.css('.chip.WEBLINK a')

    chip_label = html.css('.chip.label').first
    labels = chip_label ? chip_label.children.text.split(' ').map{|tag| "##{tag}" } : nil

    next if contents.empty?

    if title.empty?
      link_title = html.css('.chip.WEBLINK .annotation-text').text
      title = (link_title && link_title != "") ? link_title : html.css('title').text
    end

    if labels&.include?('#日報')
      labels.push date_label(Time.parse title)
      title = "日報 #{title}"
    end

    if labels&.include?('#日記')
      labels.push date_label(Time.parse title)
      title = "日記 #{title}"
    end

    pages.push({
      title: title[0..100],
      lines: [title, contents, labels].compact.flatten
    })
  end

  if(i % 1000 == 0)
    File.open("import#{i}.json", 'w') {|file| file << { pages: pages }.to_json }
    pages = []
  end
end

unless pages.empty?
  File.open("importlast.json", 'w') {|file| file << { pages: pages }.to_json }
end
