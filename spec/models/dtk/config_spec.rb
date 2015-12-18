require 'spec_helper'

describe Voog::Dtk do

  describe '.read_config' do

    context 'when a config file is provided' do

      let(:config) { Voog::Dtk.read_config nil, 'spec/fixtures/.voog' }

      it 'api_token should be exactly as configured' do
        expect(config[:api_token]).to eq('afcf30182aecfc8155d390d7d4552d14')
      end

      it 'host should be exactly as configured' do
        expect(config[:host]).to eq('voog.local')
      end

      context 'when there are multiple blocks' do
        let(:block1) { Voog::Dtk.read_config nil, 'spec/fixtures/.voog2' }
        let(:block2) { Voog::Dtk.read_config 'testblock', 'spec/fixtures/.voog2' }

        it 'should default to the first one if block is not provided' do
          expect(block1[:host]).to eq('voog.local')
        end

        it 'should read the correct options when a block is provided' do
          expect(block2[:api_token]).to eq('123')
        end

        it 'should fail when a non-existant block is provided' do
          expect{
            block3 = Voog::Dtk.read_config 'wrongname', 'spec/fixtures/.voog2'
          }.to raise_error(RuntimeError)
        end
      end

    end

    context 'when the provided filename is empty' do

      let(:config) { Voog::Dtk.read_config nil, '' }

      it 'api_token should be nil' do
        expect(config[:api_token]).to eq(nil)
      end

      it 'host should be nil' do
        expect(config[:host]).to eq(nil)
      end

    end

    context 'when a filename is not provided' do

      let(:config) { Voog::Dtk.read_config nil, nil }

      it 'api_token should be nil' do
        expect(config[:api_token]).to eq(nil)
      end

      it 'host should be nil' do
        expect(config[:host]).to eq(nil)
      end

    end

    context 'when the provided filename is invalid' do

      let(:config) { Voog::Dtk.read_config nil, 'foo.bar' }

      it 'api_token should be nil' do
        expect(config[:api_token]).to eq(nil)
      end

      it 'host should be nil' do
        expect(config[:host]).to eq(nil)
      end

    end
  end
end
