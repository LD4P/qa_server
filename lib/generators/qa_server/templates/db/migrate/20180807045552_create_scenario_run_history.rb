class CreateScenarioRunHistory < ActiveRecord::Migration[5.1]
  def change
    create_table :scenario_run_history do |t|
      t.belongs_to :scenario_run_registry
      t.integer :status, default: 2 # :good, :bad, :unknown
      t.string :authority_name
      t.string :subauthority_name
      t.string :service
      t.string :action
      t.string :url
      t.string :err_message
      t.integer :scenario_type, default: 0 # :connection, :accuracy, :performance
      t.decimal :run_time, precision: 10, scale: 4
    end
  end
end
