require 'spec_helper'
require 'ostruct'

describe 'Edicy::Liquid::Tags' do
  describe 'ContentTag' do
    before :each do
      @liquid = '{% content name="test" %}'
      @context = {
        'page' => Edicy::Liquid::Drops::PageDrop.new(NestedOpenStruct.new(
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

    context 'when a name parameter is provided' do
      it 'provides the correct value by the provided name' do
        rendered = Liquid::Template.parse(@liquid).render @context
        expect(rendered.strip).to eq('test content')
      end
    end

    context 'when a name parameter is provided but not found' do
      before :each do
        @liquid = '{% content name="missing" %}'
      end

      it 'provides an empty string' do
        rendered = Liquid::Template.parse(@liquid).render @context
        expect(rendered.strip).to eq('')
      end
    end

    context 'when a name parameter is not provided' do
      before :each do
        @liquid = '{% content %}'
      end
      it 'defaults to the content named "body"' do
        rendered = Liquid::Template.parse(@liquid).render @context
        expect(rendered.strip).to eq('default content')
      end
    end
  end
end
