require 'spec_helper'

describe HomeController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'configure'" do
    it "returns http success" do
      get 'configure'
      response.should be_success
    end
  end

  describe "GET 'fetch'" do
    it "returns http success" do
      get 'fetch'
      response.should be_success
    end
  end

  describe "GET 'help'" do
    it "returns http success" do
      get 'help'
      response.should be_success
    end
  end

end
