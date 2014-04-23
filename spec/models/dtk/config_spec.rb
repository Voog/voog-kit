require 'spec_helper'

describe Edicy::Dtk do

  describe '.read_config' do

    context 'when a config file is provided' do

      let(:config) { Edicy::Dtk.read_config 'spec/fixtures/.edicy' }

      it 'api_token should be exactly as configured' do
        expect(config[:api_token]).to eq('afcf30182aecfc8155d390d7d4552d14')
      end

      it 'host should be exactly as configured' do
        expect(config[:host]).to eq('edicy.local')
      end

    end

    context 'when the provided filename is empty' do

      let(:config) { Edicy::Dtk.read_config '' }

      it 'api_token should be nil' do
        expect(config[:api_token]).to eq(nil)
      end

      it 'host should be nil' do
        expect(config[:host]).to eq(nil)
      end

    end

    context 'when a filename is not provided' do

      let(:config) { Edicy::Dtk.read_config }

      it 'api_token should be nil' do
        expect(config[:api_token]).to eq(nil)
      end

      it 'host should be nil' do
        expect(config[:host]).to eq(nil)
      end

    end

    context 'when the provided filename is invalid' do

      let(:config) { Edicy::Dtk.read_config 'foo.bar' }

      it 'api_token should be nil' do
        expect(config[:api_token]).to eq(nil)
      end

      it 'host should be nil' do
        expect(config[:host]).to eq(nil)
      end

    end
  end
end
