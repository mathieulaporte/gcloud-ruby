# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "gcloud/logging/resource"
require "gcloud/logging/entry/http_request"
require "gcloud/logging/entry/operation"
require "gcloud/logging/entry/list"

module Gcloud
  module Logging
    ##
    # # Entry
    #
    # An individual entry in a log.
    #
    # @example
    #   require "gcloud"
    #
    #   gcloud = Gcloud.new
    #   logging = gcloud.logging
    #   entry = logging.entries.first
    #
    class Entry
      ##
      # Create an empty Entry object.
      def initialize
        @labels = {}
        @resource = Resource.new
        @http_request = HttpRequest.new
        @operation = Operation.new
      end

      ##
      # The resource name of the log to which this log entry belongs. The format
      # of the name is `projects/<project-id>/logs/<log-id>`. e.g.
      # `projects/my-projectid/logs/syslog` and
      # `projects/1234567890/logs/library.googleapis.com%2Fbook_log`
      #
      # The log ID part of resource name must be less than 512 characters long
      # and can only include the following characters: upper and lower case
      # alphanumeric characters: `[A-Za-z0-9]`; and punctuation characters:
      # forward-slash (`/`), underscore (`_`), hyphen (`-`), and period (`.`).
      # Forward-slash (`/`) characters in the log ID must be URL-encoded.
      attr_accessor :log_name

      ##
      # The monitored resource associated with this log entry. Example: a log
      # entry that reports a database error would be associated with the
      # monitored resource designating the particular database that reported the
      # error.
      attr_reader :resource

      ##
      # The time the event described by the log entry occurred. If omitted,
      # Cloud Logging will use the time the log entry is written.
      attr_accessor :timestamp

      ##
      # The severity of the log entry. The default value is `DEFAULT`.
      attr_accessor :severity

      ##
      # Helper method to determine if the severity is `DEFAULT`
      def default?
        severity == "DEFAULT"
      end

      ##
      # Helper method to determine if the severity is `DEBUG`
      def debug?
        severity == "DEBUG"
      end

      ##
      # Helper method to determine if the severity is `INFO`
      def info?
        severity == "INFO"
      end

      ##
      # Helper method to determine if the severity is `NOTICE`
      def notice?
        severity == "NOTICE"
      end

      ##
      # Helper method to determine if the severity is `WARNING`
      def warning?
        severity == "WARNING"
      end

      ##
      # Helper method to determine if the severity is `ERROR`
      def error?
        severity == "ERROR"
      end

      ##
      # Helper method to determine if the severity is `CRITICAL`
      def critical?
        severity == "CRITICAL"
      end

      ##
      # Helper method to determine if the severity is `ALERT`
      def alert?
        severity == "ALERT"
      end

      ##
      # Helper method to determine if the severity is `EMERGENCY`
      def emergency?
        severity == "EMERGENCY"
      end

      ##
      # A unique ID for the log entry. If you provide this field, the logging
      # service considers other log entries in the same log with the same ID as
      # duplicates which can be removed. If omitted, Cloud Logging will generate
      # a unique ID for this log entry.
      attr_accessor :insert_id

      ##
      # A set of user-defined data that provides additional information about
      # the log entry.
      attr_accessor :labels

      ##
      # The log entry payload, represented as either a string, a hash (JSON), or
      # a hash (protocol buffer).
      attr_accessor :payload

      ##
      # Information about the HTTP request associated with this log entry, if
      # applicable.
      attr_reader :http_request

      ##
      # Information about an operation associated with the log entry, if
      # applicable.
      attr_reader :operation

      ##
      # @private Exports the Entry to a Google API Client object.
      def to_gapi
        ret = {
          "logName" => log_name,
          "timestamp" => formatted_timestamp,
          "severity" => severity,
          "insertId" => insert_id,
          "labels" => labels
        }.delete_if { |_, v| v.nil? }
        ret.merge! payload_gapi
        ret.merge!({ "resource" => resource.to_gapi,
                     "httpRequest" => http_request.to_gapi,
                     "operation" => operation.to_gapi
                   }.delete_if { |_, v| v.empty? })
      end

      ##
      # @private Formats the timestamp for the API.
      def formatted_timestamp
        return timestamp.utc.strftime("%FT%TZ") if timestamp.respond_to? :utc
        timestamp
      end

      ##
      # @private Formats the payload for the API.
      def payload_gapi
        if payload.respond_to? :to_proto
          { "protoPayload" => payload.to_proto }
        elsif payload.respond_to? :to_hash
          { "jsonPayload" => payload.to_hash }
        else
          { "textPayload" => payload.to_s }
        end
      end

      ##
      # @private Determines if the Entry has any data.
      def empty?
        to_gapi.empty?
      end

      ##
      # @private New Entry from a Google API Client object.
      def self.from_gapi gapi
        gapi ||= {}
        entry = new.tap do |e|
          e.log_name = gapi["logName"]
          e.timestamp = Time.parse(gapi["timestamp"]) if gapi["timestamp"]
          e.severity = gapi["severity"]
          e.insert_id = gapi["insertId"]
          e.labels = hashify(gapi["labels"])
          e.payload = extract_payload(gapi)
        end
        entry.instance_eval do
          @resource = Resource.from_gapi gapi["resource"]
          @http_request = HttpRequest.from_gapi gapi["httpRequest"]
          @operation = Operation.from_gapi gapi["operation"]
        end
        entry
      end

      ##
      # @private Convert to a hash, used for labels.
      def self.hashify h
        h = h.to_hash if h.respond_to? :to_hash
        h = h.to_h    if h.respond_to? :to_h
        h
      end

      ##
      # @private Extract payload data from Google API Client object.
      def self.extract_payload gapi
        gapi["protoPayload"] || gapi["jsonPayload"] || gapi["textPayload"]
      end
    end
  end
end
