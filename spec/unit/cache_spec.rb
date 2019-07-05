require 'spec_helper'

RSpec.describe Cache do
  it 'should store a value' do
    Cache.get('mykey') { 5 }

    expect(Cache.get('mykey')).to eq(5)
  end
  it 'should set the value once' do
    Cache.get('mykey') { 5 }
    Cache.get('mykey') { 3 }
    expect(Cache.get('mykey')).to eq(5)
  end
  it 'should not evaluate the second time if the resulting value is nil' do
    computation = double('computation', compute: nil)
    Cache.get('mykey') { computation.compute }
    Cache.get('mykey') { computation.compute }
    expect(computation).to have_received(:compute).once
  end
  it 'clears the cache' do
    Cache.get('mykey') { 5 }
    Cache.clear
    Cache.get('mykey') { 3 }
    expect(Cache.get('mykey')).to eq(3)
  end

end
