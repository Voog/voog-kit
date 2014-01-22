require 'spec_helper'

describe 'Edicy::Liquid::Tags' do
  describe 'MenuAddTag' do
    context 'when parent is specified' do
      it 'sets the link text to "Add subpage"' do
        @liquid = '{% menuadd parent="site.hidden_children" %}'
        rendered = Liquid::Template.parse(@liquid).render {}
        link_text = /\">(Add.*)<\//.match(rendered)[1]
        expect(link_text).to eq('Add subpage')

      end
    end

    context 'when parent is not specified' do
      it 'sets the link text to just "Add"' do
        @liquid = '{% menuadd %}'
        rendered = Liquid::Template.parse(@liquid).render {}
        link_text = /\">(Add.*)<\//.match(rendered)[1]
        expect(link_text).to eq('Add')

      end
    end
  end
end
