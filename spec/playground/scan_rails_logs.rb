#!/usr/bin/env ruby
# encoding: utf-8
require "uri"
require File.dirname(__FILE__) + "/../spec_helper"

# A very basic log stats program to show the use of Teeth.  Gives the top 20 
# URLs and the top 10 Errors.  Supports Ruby 1.9, though it seems a bit 
# slower than 1.8 (?)

results = Hash.new(0)
error_results = Hash.new(0)
if RUBY_VERSION >= "1.9.0"
  filename = ARGV[0].dup.force_encoding("ASCII-8BIT") # 1.9 is weird on Mac
else
  filename = ARGV[0]
end

File.open(filename, "r") do |f|
  n_processed = n_completed = n_errors = 0
  while line = f.gets
    tokens = line.scan_rails_logs
    if tokens[:teaser] && tokens[:teaser].first == "Processing"
      n_processed += 1
      results[tokens[:controller_action].first] += 1
    end
    if tokens[:error]
      n_errors += 1
      error_results[tokens[:error].first] += 1
    end
    if tokens[:url] && tokens[:teaser].first == "Completed in"
      n_completed +=1
    end
  end
  puts "=" * 80
  puts "Totals"
  puts "#{n_processed} requests processed"
  puts "#{n_completed} requests completed"
  results_ary = results.map { |url, hits| [url, hits] }.sort { |a, b| b.last <=> a.last }
  puts "=" * 80
  puts "\nTop 20 URLs"
  puts "=" * 80
  puts " URL".ljust(40) + " | " + "Hits"
  puts "-" * 80
  results_ary[0, 20].each do |url_hits|
    puts url_hits.first.ljust(40) + " | " + url_hits.last.to_s
  end
  errors_ary = error_results.map { |error, hits| [error, hits] }.sort { |a, b| b.last <=> a.last }
  puts "=" * 80
  puts "\nTop 10 Errors"
  puts "=" * 80
  puts " Error".ljust(40) + " | " + "Hits"
  puts "-" * 80
  errors_ary[0, 10].each do |error_hits|
    puts error_hits.first.ljust(40) + " | " + error_hits.last.to_s
  end
end