require "../spec_helper"

module ValidationSpec
  class User
    include Clear::Model
    column user_name : String   # Must be present
    column first_name : String? # No presence
  end

  class ValidateNotEmpty
    include Clear::Model

    column a : String # Must be present

    def validate
      ensure_than a, "must not be empty", &.strip.!=("")
    end
  end

  class MultiValidation
    include Clear::Model

    column email : String

    def validate
      ensure_than email, "must be email", &.strip.=~(/^[a-z0-9_+\.]+@[a-z0-9_\.]+$/i)
      ensure_than email, "must not be a free email" do |value|
        v = value.strip

        ![
          /gmail\.com$/,
          /hotmail\.[A-Za-z\.]+$/,
          /yahoo.[A-Za-z\.]+$/,
        ].any? { |x| v =~ x }
      end
    end
  end

  describe "Clear::Model Validation" do
    it "can validate presence using the type of the column " do
      u = User.new
      u.valid?.should eq(false)
      u.print_errors.should eq("user_name: must be present")
      u.user_name = "helloworld"
      u.valid?.should eq(true)
      u.errors.size.should eq(0)
    end

    it "won't use the presence validator if persisted" do
      # In case we select a user from db, byt without user_name in the
      # selection of column, then the model is still valid for update even
      # without the presence of user_name.
      u = User.new persisted: true
      u.valid?.should eq(true)
    end

    it "can validate multiple columns" do
      m = MultiValidation.new
      m.email = "test"

      m.valid?.should eq(false)
      m.print_errors.should eq("email: must be email")

      m.email = "test@gmail.com"
      m.valid?.should eq(false)
      m.print_errors.should eq("email: must not be a free email")

      m.email = "abdul(at)gmail.com"
      m.valid?.should eq(false)
      m.print_errors.should eq("email: must be email, must not be a free email")
    end

    it "can validate" do
      v = ValidateNotEmpty.new
      v.a = ""
      v.valid?.should eq(false)
      v.print_errors.should eq("a: must not be empty")

      v.a = "toto"
      v.valid?.should eq(true)
      v.errors.size.should eq(0)
    end
  end
end
