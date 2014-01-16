require 'spec_helper'
require 'ostruct'

describe 'Edicy::Liquid::Tags', focus: true do
  describe 'EditableTag' do
    before :each do
      @context = {
        'page' => Edicy::Liquid::Drops::PageDrop.new(NestedOpenStruct.new(
          'title' => 'page title',
          'contents' => [{
            'name' => 'test',
            'text' => { 'body' => 'test content' }
          }, {
            'name' => 'body',
            'text' => { 'body' => 'default content' }
          }]
        )),
        'language' => Edicy::Liquid::Drops::LanguageDrop.new(
          NestedOpenStruct.new(
            'contents' => [{
              'name' => 'test',
              'text' => { 'body' => 'test content' }
            }]
          )
        )
      }
    end

    context 'when a key parameter is provided' do
      context 'when the parameter is found within context' do
        it 'returns the parameter value' do
          @liquid = '{% editable page.title %}'
          rendered = Liquid::Template.parse(@liquid).render @context
          expect(rendered.strip).to eq('page title')    
        end
      end

      context 'when the parameter is not found within context' do
        it 'returns an empty string' do
          @liquid = '{% editable page.name %}'
          rendered = Liquid::Template.parse(@liquid).render @context
          expect(rendered.strip).to eq('')    
        end
      end
    end

    context 'when a key parameter is not provided' do
      it 'returns an empty string' do
        @liquid = '{% editable %}'
        rendered = Liquid::Template.parse(@liquid).render @context
        expect(rendered.strip).to eq('')
      end
    end
  end
end