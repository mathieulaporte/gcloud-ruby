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


module Gcloud
  module Logging
    ##
    # # Logger
    #
    # A (mostly) API compatible logger for ruby's Logger.
    class Logger
      ##
      # @private The logging object.
      attr_accessor :logging

      ##
      # @private The Google Cloud log_name to write the log entry with.
      attr_reader :log_name

      ##
      # @private The Google Cloud resource to write the log entry with.
      attr_reader :resource

      ##
      # @private The Google Cloud labels to write the log entry with.
      attr_reader :labels

      ##
      # @private Creates a new Logger instance.
      def initialize logging, log_name, resource, labels = nil
        @logging = logging
        @log_name = log_name
        @resource = resource
        @labels = labels
        @level = 0 # DEBUG is the default behavior
      end

      ##
      # Log a DEBUG message.
      def debug message = nil, &block
        if block_given?
          add 0, nil, message, &block
        else
          add 0, message, nil, &block
        end
      end

      ##
      # Log an INFO message.
      def info message = nil, &block
        if block_given?
          add 1, nil, message, &block
        else
          add 1, message, nil, &block
        end
      end

      ##
      # Log a WARN message.
      def warn message = nil, &block
        if block_given?
          add 2, nil, message, &block
        else
          add 2, message, nil, &block
        end
      end

      ##
      # Log an ERROR message.
      def error message = nil, &block
        if block_given?
          add 3, nil, message, &block
        else
          add 3, message, nil, &block
        end
      end

      ##
      # Log a FATAL message.
      def fatal message = nil, &block
        if block_given?
          add 4, nil, message, &block
        else
          add 4, message, nil, &block
        end
      end

      ##
      # Log an UNKNOWN message. This will be printed no matter what the logger's
      # level is.
      def unknown message = nil, &block
        if block_given?
          add 5, nil, message, &block
        else
          add 5, message, nil, &block
        end
      end

      ##
      # Log a message if the given severity is high enough. This is the generic
      # logging method. Users will be more inclined to use {#debug}, {#info},
      # {#warn}, {#error}, and {#fatal}.
      def add severity, message = nil, progname = nil
        severity = derive_severity(severity) || 5 # 5 is UNKNOWN/DEFAULT
        return true if severity < @level

        if message.nil?
          if block_given?
            message = yield
          else
            message = progname
            # progname = nil # TODO: Figure out what to do with the progname
          end
        end

        write_entry severity, message
      end
      alias_method :log, :add

      ##
      # Returns true if the current severity level allows for sending DEBUG
      # messages.
      def debug?
        @level <= 0
      end

      ##
      # Returns true if the current severity level allows for sending INFO
      # messages.
      def info?
        @level <= 1
      end

      ##
      # Returns true if the current severity level allows for sending WARN
      # messages.
      def warn?
        @level <= 2
      end

      ##
      # Returns true if the current severity level allows for sending ERROR
      # messages.
      def error?
        @level <= 3
      end

      ##
      # Returns true if the current severity level allows for sending FATAL
      # messages.
      def fatal?
        @level <= 4
      end

      ##
      # Set logging severity threshold.
      def level= severity
        new_level = derive_severity severity
        fail ArgumentError, "invalid log level: #{severity}" if new_level.nil?
        @level = new_level
      end
      alias_method :sev_threshold=, :level=

      protected

      ##
      # @private Write a log entry to Google Cloud Logging service.
      def write_entry severity, message
        entry = logging.entry.tap do |e|
          e.severity = gcloud_severity(severity)
          e.payload = message
        end

        logging.write_entries entry, log_name: log_name,
                                     resource: resource,
                                     labels: labels
      end

      ##
      # @private Get the logger level number from severity value object.
      def derive_severity severity
        return severity if severity.is_a? Integer

        downcase_severity = severity.to_s.downcase
        case downcase_severity
        when "debug".freeze then 0
        when "info".freeze then 1
        when "warn".freeze then 2
        when "error".freeze then 3
        when "fatal".freeze then 4
        when "unknown".freeze then 5
        else nil
        end
      end

      ##
      # @private Get Google Cloud deverity from logger level number.
      def gcloud_severity severity_int
        %w(DEBUG INFO WARNING ERROR CRITICAL DEFAULT)[severity_int]
      rescue
        "DEFAULT"
      end
    end
  end
end
