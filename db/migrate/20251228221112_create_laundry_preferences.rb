class CreateLaundryPreferences < ActiveRecord::Migration[7.1]
  def change
    create_table :laundry_preferences, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.integer :detergent_type, default: 0
      t.integer :water_temperature, default: 1
      t.integer :dry_method, default: 0
      t.boolean :separate_kids_clothing, default: false
      t.boolean :sensitive_skin, default: false
      t.boolean :remove_pet_hair, default: false
      t.boolean :fold_only, default: false
      t.text :personal_notes

      t.timestamps
    end
  end
end
