# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer::MonitorStatus::HistoryPresenter do
  let(:presenter) { described_class.new(parent: nil, historical_summary_data: historical_summary_data) }
  # rubocop:disable Layout/ExtraSpacing
  let(:historical_summary_data) do
    # { 'auth_name' => { good: count_of_passing_tests, bad: count_of_failing_tests } }
    {
      'GOOD_AUTH'   => { good:    0, bad: 1000 },
      'BARELY_GOOD' => { good:   49, bad:  951 },
      'OK_AUTH'     => { good:   50, bad:  950 },
      'STILL_OK'    => { good:   51, bad:  949 },
      'BARELY_OK'   => { good:   99, bad:  901 },
      'BAD_AUTH'    => { good:  100, bad:  900 },
      'STILL_BAD'   => { good:  101, bad:  899 },
      'REALLY_BAD'  => { good:  500, bad:  500 },
      'HORRIBLE'    => { good: 1000, bad:    0 }
    }
    # rubocop:enable Layout/ExtraSpacing
  end

  describe '.failure_style_class' do
    context 'returns NEUTRAL style' do
      let(:expected_css_style) { "status-neutral" }
      let(:zero_failure_entry) { ['GOOD_AUTH',   { good: 1000, bad:  0 }] } # rubocop:disable Layout/ExtraSpacing
      let(:just_below_caution) { ['BARELY_GOOD', { good:  951, bad: 49 }] } # rubocop:disable Layout/ExtraSpacing

      it 'when no failures' do
        expect(presenter.failure_style_class(zero_failure_entry)).to eq expected_css_style
      end

      it 'when percent of failures is just below the CAUTION_THRESHOLD' do
        expect(presenter.failure_style_class(just_below_caution)).to eq expected_css_style
      end
    end

    context 'returns CAUTION style' do
      let(:expected_css_style) { "status-unknown" }
      let(:equal_caution)      { ['OK_AUTH',   { good: 950, bad: 50 }] }
      let(:just_above_caution) { ['STILL_OK',  { good: 949, bad: 51 }] }
      let(:just_below_warning) { ['BARELY_OK', { good: 901, bad: 99 }] }

      it 'when percent of failures is equal to CAUTION_THRESHOLD' do
        expect(presenter.failure_style_class(equal_caution)).to eq expected_css_style
      end

      it 'when percent of failures is just above CAUTION_THRESHOLD' do
        expect(presenter.failure_style_class(just_above_caution)).to eq expected_css_style
      end

      it 'when percent of failures is just below WARNING_THRESHOLD' do
        expect(presenter.failure_style_class(just_below_warning)).to eq expected_css_style
      end
    end

    context 'returns WARNING style' do
      let(:expected_css_style) { "status-bad" }
      let(:equal_warning)      { ['BAD_AUTH',   { good: 900, bad:  100 }] }
      let(:just_above_warning) { ['STILL_BAD',  { good: 899, bad:  101 }] }
      let(:well_above_warning) { ['REALLY_BAD', { good: 500, bad:  500 }] }
      let(:all_failures)       { ['HORRIBLE',   { good:   0, bad: 1000 }] }

      it 'when percent of failures is equal to WARNING_THRESHOLD' do
        expect(presenter.failure_style_class(equal_warning)).to eq expected_css_style
      end

      it 'when percent of failures is just above WARNING_THRESHOLD' do
        expect(presenter.failure_style_class(just_above_warning)).to eq expected_css_style
      end

      it 'when percent of failures is well above WARNING_THRESHOLD' do
        expect(presenter.failure_style_class(well_above_warning)).to eq expected_css_style
      end

      it 'when percent of failures is 100%' do
        expect(presenter.failure_style_class(all_failures)).to eq expected_css_style
      end
    end
  end
end
