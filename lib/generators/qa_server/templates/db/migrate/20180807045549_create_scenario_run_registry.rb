class CreateScenarioRunRegistry < ActiveRecord::Migration[5.1]
  def change
    create_table :scenario_run_registry do |t|
      t.datetime :dt_stamp
    end
  end
end
