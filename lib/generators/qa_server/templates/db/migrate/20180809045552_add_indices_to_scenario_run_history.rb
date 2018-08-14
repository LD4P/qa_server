class AddIndicesToScenarioRunHistory < ActiveRecord::Migration[5.1]
  def change
    add_index :scenario_run_history, :url
    add_index :scenario_run_history, :status
    add_index :scenario_run_history, :authority_name
    add_index :scenario_run_history, :scenario_type
  end
end
