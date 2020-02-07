# frozen_string_literal: true
require 'spec_helper'

RSpec.describe QaServer::TimePeriodService do
  before { allow(QaServer).to receive(:current_time).and_return(Time.find_zone('Eastern Time (US & Canada)').local(2020, 1, 1)) }

  let(:end_range) { QaServer.current_time }

  let(:auth_name) { 'LOC_DIRECT' }
  let(:auth_table) { :scenario_run_history }
  let(:dt_table) { :scenario_run_registry }

  describe '.where_clause_for_last_24_hours' do
    let(:end_hour) { end_range }
    let(:start_hour) { end_hour - 1.day }

    context 'when auth_name is nil' do
      context 'and auth_table is nil' do
        context 'and dt_table is nil' do
          let(:expected_result) do
            { dt_stamp: start_hour..end_hour }
          end
          it 'returns where clause with dt_stamp range only' do
            expect(described_class.where_clause_for_last_24_hours).to eq expected_result
          end
        end

        context 'and dt_table is present' do
          let(:expected_result) do
            { scenario_run_registry: { dt_stamp: start_hour..end_hour } }
          end
          it 'returns where clause with dt_stamp range limited to a specified table' do
            expect(described_class.where_clause_for_last_24_hours(dt_table: dt_table)).to eq expected_result
          end
        end
      end

      context 'and auth_table is present' do
        it 'raise error' do
          expect { described_class.where_clause_for_last_24_hours(auth_table: auth_table) }
            .to raise_error ArgumentError, "Do not specify auth_table when auth_name is not specified"
        end
      end
    end

    context 'when auth_name is present' do
      context 'and auth_table is nil' do
        context 'and dt_table is nil' do
          let(:expected_result) do
            {
              dt_stamp: start_hour..end_hour,
              authority: auth_name
            }
          end
          it 'returns where clause with dt_stamp range and authname' do
            expect(described_class.where_clause_for_last_24_hours(auth_name: auth_name)).to eq expected_result
          end
        end

        context 'and dt_table is present' do
          it 'raises error' do
            expect { described_class.where_clause_for_last_24_hours(auth_name: auth_name, dt_table: dt_table) }
              .to raise_error ArgumentError, "Either both table names need to be specified or neither"
          end
        end
      end

      context 'and auth_table is present' do
        context 'and dt_table is nil' do
          it 'raises error' do
            expect { described_class.where_clause_for_last_24_hours(auth_name: auth_name, auth_table: auth_table) }
              .to raise_error ArgumentError, "Either both table names need to be specified or neither"
          end
        end

        context 'and dt_table is present' do
          let(:expected_result) do
            {
              scenario_run_registry: { dt_stamp: start_hour..end_hour },
              scenario_run_history: { authority: auth_name }
            }
          end
          it 'returns where clause with dt_stamp range and authname limited to the specified tables' do
            expect(described_class.where_clause_for_last_24_hours(auth_name: auth_name, auth_table: auth_table, dt_table: dt_table)).to eq expected_result
          end
        end
      end
    end
  end

  describe '.where_clause_for_last_30_days' do
    let(:end_day) { end_range }
    let(:start_day) { end_day - 1.month }

    context 'when auth_name is nil' do
      context 'and auth_table is nil' do
        context 'and dt_table is nil' do
          let(:expected_result) do
            { dt_stamp: start_day..end_day }
          end
          it 'returns where clause with dt_stamp range only' do
            expect(described_class.where_clause_for_last_30_days).to eq expected_result
          end
        end

        context 'and dt_table is present' do
          let(:expected_result) do
            { scenario_run_registry: { dt_stamp: start_day..end_day } }
          end
          it 'returns where clause with dt_stamp range limited to a specified table' do
            expect(described_class.where_clause_for_last_30_days(dt_table: dt_table)).to eq expected_result
          end
        end
      end

      context 'and auth_table is present' do
        it 'raise error' do
          expect { described_class.where_clause_for_last_30_days(auth_table: auth_table) }
            .to raise_error ArgumentError, "Do not specify auth_table when auth_name is not specified"
        end
      end
    end

    context 'when auth_name is present' do
      context 'and auth_table is nil' do
        context 'and dt_table is nil' do
          let(:expected_result) do
            {
              dt_stamp: start_day..end_day,
              authority: auth_name
            }
          end
          it 'returns where clause with dt_stamp range and authname' do
            expect(described_class.where_clause_for_last_30_days(auth_name: auth_name)).to eq expected_result
          end
        end

        context 'and dt_table is present' do
          it 'raises error' do
            expect { described_class.where_clause_for_last_30_days(auth_name: auth_name, dt_table: dt_table) }
              .to raise_error ArgumentError, "Either both table names need to be specified or neither"
          end
        end
      end

      context 'and auth_table is present' do
        context 'and dt_table is nil' do
          it 'raises error' do
            expect { described_class.where_clause_for_last_30_days(auth_name: auth_name, auth_table: auth_table) }
              .to raise_error ArgumentError, "Either both table names need to be specified or neither"
          end
        end

        context 'and dt_table is present' do
          let(:expected_result) do
            {
              scenario_run_registry: { dt_stamp: start_day..end_day },
              scenario_run_history: { authority: auth_name }
            }
          end
          it 'returns where clause with dt_stamp range and authname limited to the specified tables' do
            expect(described_class.where_clause_for_last_30_days(auth_name: auth_name, auth_table: auth_table, dt_table: dt_table)).to eq expected_result
          end
        end
      end
    end
  end

  describe '.where_clause_for_last_12_months' do
    let(:end_month) { end_range }
    let(:start_month) { end_month - 1.year }

    context 'when auth_name is nil' do
      context 'and auth_table is nil' do
        context 'and dt_table is nil' do
          let(:expected_result) do
            { dt_stamp: start_month..end_month }
          end
          it 'returns where clause with dt_stamp range only' do
            expect(described_class.where_clause_for_last_12_months).to eq expected_result
          end
        end

        context 'and dt_table is present' do
          let(:expected_result) do
            { scenario_run_registry: { dt_stamp: start_month..end_month } }
          end
          it 'returns where clause with dt_stamp range limited to a specified table' do
            expect(described_class.where_clause_for_last_12_months(dt_table: dt_table)).to eq expected_result
          end
        end
      end

      context 'and auth_table is present' do
        it 'raise error' do
          expect { described_class.where_clause_for_last_12_months(auth_table: auth_table) }
            .to raise_error ArgumentError, "Do not specify auth_table when auth_name is not specified"
        end
      end
    end

    context 'when auth_name is present' do
      context 'and auth_table is nil' do
        context 'and dt_table is nil' do
          let(:expected_result) do
            {
              dt_stamp: start_month..end_month,
              authority: auth_name
            }
          end
          it 'returns where clause with dt_stamp range and authname' do
            expect(described_class.where_clause_for_last_12_months(auth_name: auth_name)).to eq expected_result
          end
        end

        context 'and dt_table is present' do
          it 'raises error' do
            expect { described_class.where_clause_for_last_12_months(auth_name: auth_name, dt_table: dt_table) }
              .to raise_error ArgumentError, "Either both table names need to be specified or neither"
          end
        end
      end

      context 'and auth_table is present' do
        context 'and dt_table is nil' do
          it 'raises error' do
            expect { described_class.where_clause_for_last_12_months(auth_name: auth_name, auth_table: auth_table) }
              .to raise_error ArgumentError, "Either both table names need to be specified or neither"
          end
        end

        context 'and dt_table is present' do
          let(:expected_result) do
            {
              scenario_run_registry: { dt_stamp: start_month..end_month },
              scenario_run_history: { authority: auth_name }
            }
          end
          it 'returns where clause with dt_stamp range and authname limited to the specified tables' do
            expect(described_class.where_clause_for_last_12_months(auth_name: auth_name, auth_table: auth_table, dt_table: dt_table)).to eq expected_result
          end
        end
      end
    end
  end
end
