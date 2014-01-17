require 'spec_helper'

describe 'Edicy::Liquid::Filters' do
  describe 'LocalizationFilters' do
    before :each do
      @liquid = '{{ "comment_body_blank" | lc }}'
    end

    context 'when a string is provided' do
      context 'and it is a valid key' do
        it 'returns the corresponding text' do
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered.strip).to eq('Comment is empty!')
        end
      end

      context 'and it is not a valid key' do
        it 'converts the key into normal text' do
          @liquid = '{{ "invalid_key" | lc }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered.strip).to eq('Invalid key')
        end
      end
    end

    context 'when the provided key is not a string' do
      it 'returns nothing' do
        @liquid = '{{ foobar | lc }}'
        rendered = Liquid::Template.parse(@liquid).render {}
        expect(rendered).to eq('')
      end
    end
  end
end
