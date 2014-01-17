require 'spec_helper'

describe 'Edicy::Liquid::Filters::StandardFilters' do
  describe '#format_date' do

    context 'when a date string is provided' do
      context 'with no format' do
        it 'returns the date with the default format' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_date:"default" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('16.01.2014')
        end
      end

      context 'with an empty format string' do
        it 'returns the original date string' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_date:"" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('2014-01-16 20:05:28')
        end
      end

      context 'with a default format string' do
        it 'returns the date with the default format' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_date:"long" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('January 16, 2014')
        end
      end

      context 'with a custom format string' do
        it 'returns the date with the provided format' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_date:"%B %d of the year %Y" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('January 16 of the year 2014')
        end
      end
    end

  end

  describe '#format_time' do
    context 'when a time string is provided' do
      context 'with no format' do
        it 'returns the time with the default format' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_time:"default" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('Thu, 16 Jan 2014 20:05')
        end
      end

      context 'with an empty format string' do
        it 'returns the original time string' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_time:"" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('2014-01-16 20:05:28')
        end
      end

      context 'with a default format string' do
        it 'returns the time with the default format' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_time:"long" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('January 16, 2014 20:05')
        end
      end

      context 'with a custom format string' do
        it 'returns the time with the provided format' do
          @liquid = '{{ "2014-01-16 20:05:28" | format_time:"%B %d of the year %Y, %H:%M" }}'
          rendered = Liquid::Template.parse(@liquid).render {}
          expect(rendered).to eq('January 16 of the year 2014, 20:05')
        end
      end
    end
  end
end
