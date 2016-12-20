#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'

require 'colorize'
require 'pry'
require 'csv'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko(url)
  Nokogiri::HTML(open(url).read) 
end

def datefrom(date)
  Date.parse(date)
end

@BASE = 'http://demo.cratica.org'
url = @BASE + '/deputados/'
page = noko(url)

added = Hash.new(0)

page.css('ul.mp-list li').each do |entry|
  mp_url = @BASE + entry.css('a/@href').text
  party = entry.css('span.party').text.strip

  mp = noko(mp_url)
  mp_data = { 
    id: mp_url.split('/').last,
    name: entry.css('span.name').text.strip,
    full_name: mp.xpath('//li[@class="single-field" and .//p[contains(.,"complet")]]/h5').text.strip,
    photo: mp.css('p.mp-photo img/@src').text,
    email: mp.css('ul.mp-details a[href^=mailto]/@href').text.gsub('mailto:',''),
    official_website: mp.css('ul.mp-details a[@href*="parlamento.pt/DeputadoGP/Paginas/Biografia"]/@href').text,
    wikipedia: mp.css('ul.mp-details a[@href*="wikipedia.org"]/@href').text,
    twitter: mp.css('ul.mp-details a[@href*="twitter.com"]/@href').text,
    source: mp_url
  }
  mp_data[:photo].prepend @BASE unless mp_data[:photo].nil? or mp_data[:photo].empty?
  mp_data[:identifier__parlamento] = mp_data[:official_website][/BID=(\d+)/, 1]

  mandatos = mp.xpath('//h4[contains(.,"Mandatos")]/../ul/li/text()')
  mandatos.each do |m|
    # There's almost certainly a way to do this in the XPath, but I couldn't get it to work
    next unless m.text[/Legislatura/]
    (termname, party, con_and_date) = m.text.split("\u2013").map(&:strip)
    (area, start_date, end_date) = con_and_date.match(/(.*) \(de (.*) a (.*)\)/).captures
    term_data = {
      id: termname[/^(\d+)/,1],
    }

    data = mp_data.merge({
      term: term_data[:id],
      party: party,
      area: area,
    })
    ScraperWiki.save_sqlite([:id, :term], data)
    added[term_data[:id]] += 1
  end

end
puts "  Added #{added}"


