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

require "helper"

describe Gcloud::Logging::Project, :metrics, :mock_logging do
  it "lists metrics" do
    num_metrics = 3
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(num_metrics)]
    end

    metrics = logging.metrics
    metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    metrics.size.must_equal num_metrics
  end

  it "lists metrics with find_metrics alias" do
    num_metrics = 3
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(num_metrics)]
    end

    metrics = logging.find_metrics
    metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    metrics.size.must_equal num_metrics
  end

  it "paginates metrics" do
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      env.params.wont_include "pageToken"
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(3, "next_page_token")]
    end
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      env.params.must_include "pageToken"
      env.params["pageToken"].must_equal "next_page_token"
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(2)]
    end

    first_metrics = logging.metrics
    first_metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    first_metrics.count.must_equal 3
    first_metrics.token.wont_be :nil?
    first_metrics.token.must_equal "next_page_token"

    second_metrics = logging.metrics token: first_metrics.token
    second_metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    second_metrics.count.must_equal 2
    second_metrics.token.must_be :nil?
  end

  it "paginates metrics with next? and next" do
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      env.params.wont_include "pageToken"
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(3, "next_page_token")]
    end
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      env.params.must_include "pageToken"
      env.params["pageToken"].must_equal "next_page_token"
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(2)]
    end

    first_metrics = logging.metrics
    first_metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    first_metrics.count.must_equal 3
    first_metrics.next?.must_equal true #must_be :next?

    second_metrics = first_metrics.next
    second_metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    second_metrics.count.must_equal 2
    second_metrics.next?.must_equal false #wont_be :next?
  end

  it "paginates metrics with max set" do
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      env.params.must_include "maxResults"
      env.params["maxResults"].must_equal "3"
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(3, "next_page_token")]
    end

    metrics = logging.metrics max: 3
    metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    metrics.count.must_equal 3
    metrics.token.wont_be :nil?
    metrics.token.must_equal "next_page_token"
  end

  it "paginates metrics without max set" do
    mock_connection.get "/v2beta1/projects/#{project}/metrics" do |env|
      env.params.wont_include "maxResults"
      [200, {"Content-Type"=>"application/json"},
       list_metrics_json(3, "next_page_token")]
    end

    metrics = logging.metrics
    metrics.each { |m| m.must_be_kind_of Gcloud::Logging::Metric }
    metrics.count.must_equal 3
    metrics.token.wont_be :nil?
    metrics.token.must_equal "next_page_token"
  end

  it "creates a metric" do
    new_metric_name = "new-metric-#{Time.now.to_i}"

    mock_connection.post "/v2beta1/projects/#{project}/metrics" do |env|
      metric_json = JSON.parse env.body
      metric_json["name"].must_equal new_metric_name
      metric_json["description"].must_be :nil?
      metric_json["filter"].must_be :nil?
      [200, {"Content-Type"=>"application/json"},
       empty_metric_hash.merge(metric_json.delete_if { |_, v| v.nil? }).to_json]
    end

    metric = logging.create_metric new_metric_name
    metric.must_be_kind_of Gcloud::Logging::Metric
    metric.name.must_equal new_metric_name
    metric.description.must_be :empty?
    metric.filter.must_be :empty?
  end

  it "creates a metric with additional attributes" do
    new_metric_name = "new-metric-#{Time.now.to_i}"
    new_metric_description = "New Metric (#{Time.now.to_i})"
    new_metric_filter = "logName:syslog AND severity>=WARN"

    mock_connection.post "/v2beta1/projects/#{project}/metrics" do |env|
      metric_json = JSON.parse env.body
      metric_json["name"].must_equal new_metric_name
      metric_json["description"].must_equal new_metric_description
      metric_json["filter"].must_equal new_metric_filter

      [200, {"Content-Type"=>"application/json"},
       empty_metric_hash.merge(metric_json.delete_if { |_, v| v.nil? }).to_json]
    end

    metric = logging.create_metric new_metric_name, description: new_metric_description,
      filter: new_metric_filter
    metric.must_be_kind_of Gcloud::Logging::Metric
    metric.name.must_equal new_metric_name
    metric.description.must_equal new_metric_description
    metric.filter.must_equal new_metric_filter
  end

  it "gets a metric" do
    metric_name = "existing-metric-#{Time.now.to_i}"

    mock_connection.get "/v2beta1/projects/#{project}/metrics/#{metric_name}" do |env|
      [200, {"Content-Type"=>"application/json"},
       random_metric_hash.merge("name" => metric_name).to_json]
    end

    metric = logging.metric metric_name
    metric.must_be_kind_of Gcloud::Logging::Metric
    metric.name.must_equal metric_name
  end

  def list_metrics_json count = 2, token = nil
    {
      metrics: count.times.map { random_metric_hash },
      nextPageToken: token
    }.delete_if { |_, v| v.nil? }.to_json
  end

  def empty_metric_hash
    {
      "name"                => "",
      "description"         => "",
      "filter"              => ""
    }
  end
end
