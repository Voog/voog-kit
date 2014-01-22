require 'spec_helper'

describe 'Edicy::Liquid::Tags' do
  describe 'AddButtonTag' do
    before :each do
      @liquid = '{% addbutton %}'
    end

    context 'when parent page is a blog' do
      it 'sets the link text to "New post"' do
        @context = {
          'page' => Edicy::Liquid::Drops::PageDrop.new(NestedOpenStruct.new(
            'content_type' => 'blog'
          ))
        }
        rendered = Liquid::Template.parse(@liquid).render @context
        link_text = /\"(>New .+)<\//.match(rendered)[1]
        expect(link_text).to eq('New post')
      end
    end

    context 'when parent page is an elements page' do
      it 'sets the link text to "New element"' do
        @context = {
          'page' => Edicy::Liquid::Drops::PageDrop.new(NestedOpenStruct.new(
            'content_type' => 'elements'
          ))
        }
        rendered = Liquid::Template.parse(@liquid).render @context
        link_text = /\">(New .+)<\//.match(rendered)[1]
        expect(link_text).to eq('New element')
      end
    end

    context 'when parent page\'s content type is unknown' do
      it 'defaults to "New element"' do
        @context = {
          'page' => Edicy::Liquid::Drops::PageDrop.new(NestedOpenStruct.new(
            'content_type' => nil
          ))
        }
        rendered = Liquid::Template.parse(@liquid).render @context
        link_text = /\">(New .+)<\//.match(rendered)[1]
        expect(link_text).to eq('New element')
      end
    end
  end
end
