require "zip_tax/version"
require 'net/http'
require 'json'

module ZipTax
  HOST = 'api.zip-tax.com'
  @@key ||= nil
  
  def self.key=(key)
    @@key = key
  end
  
  def self.key
    @@key
  end
  
  def self.request(options = {})
    key = @@key
    raise ArgumentError, "Options must be a Hash, #{options.class} given" unless options.is_a?(Hash)
    raise ArgumentError, "Zip-Tax API key must be set using ZipTax.key=" if key.nil?
    raise ArgumentError, "You must specify at least a zip" unless options[:postalcode]
    
    options[:key] = key

    path = "/request/v20?#{self.to_query(options)}"

    response = JSON.parse(Net::HTTP.get(HOST, path))

    if response["rCode"] != 100
      msg = case response["rCode"]
      when 101 
        "Invalid Key"
      when 102 
        "Invalid State"
      when 103 
        "Invalid City"
      when 104 
        "Invalid Postal Code"
      when 105 
        "Invalid Format"
      end
      raise ArgumentError, msg
    end

    raise StandardError, "Zip-Tax returned an empty response using those options #{options.except(:key)}" if response["results"].empty?
    return response
  end

  # we don't use the native rails to_query in case we use this gem outside of rails
  def self.to_query(hsh)
    hsh.map {|k, v| "#{k}=#{CGI::escape v.to_s}" }.join("&")
  end
  
  def self.rate(options = {})
    response = request(options)
    options[:state].nil? || options[:state].upcase == response['results'][0]['geoState'] ? response['results'][0]['taxSales'] : 0.0
  end
  
  def self.info(options = {})
    response = request(options)
    return response['results'][0]
  end
end
