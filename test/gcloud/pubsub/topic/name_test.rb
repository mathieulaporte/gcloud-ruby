# Copyright 2015 Google Inc. All rights reserved.
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

describe Gcloud::Pubsub::Topic, :name, :mock_pubsub do
  let(:topic_name) { "topic-name-goes-here" }
  let(:topic) { Gcloud::Pubsub::Topic.from_gapi JSON.parse(topic_json(topic_name)),
                                                pubsub.connection }

  it "gives the name returned from the HTTP method" do
    topic.name.must_equal "projects/#{project}/topics/#{topic_name}"
  end

  describe "lazy topic with default autocreate" do
    let(:topic) { Gcloud::Pubsub::Topic.new_lazy topic_name,
                                                 pubsub.connection }

    it "matches the name returned from the HTTP method" do
      topic.name.must_equal "projects/#{project}/topics/#{topic_name}"
    end
  end

  describe "lazy topic with explicit autocreate" do
    let(:topic) { Gcloud::Pubsub::Topic.new_lazy topic_name,
                                                 pubsub.connection,
                                                 autocreate: true }

    it "matches the name returned from the HTTP method" do
      topic.name.must_equal "projects/#{project}/topics/#{topic_name}"
    end
  end

  describe "lazy topic without autocomplete" do
    let(:topic) { Gcloud::Pubsub::Topic.new_lazy topic_name,
                                                 pubsub.connection,
                                                 autocreate: false }

    it "matches the name returned from the HTTP method" do
      topic.name.must_equal "projects/#{project}/topics/#{topic_name}"
    end
  end
end
