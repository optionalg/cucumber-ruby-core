require 'cucumber/core/test/runner'
require 'cucumber/core/test/case'
require 'cucumber/core/test/step'

module Cucumber::Core::Test
  describe Runner do

    let(:test_case) { Case.new(test_steps, source) }
    let(:source)    { double }
    let(:runner)    { Runner.new(report) }
    let(:report)    { double.as_null_object }
    let(:passing)   { Step.new([double]).map {} }
    let(:failing)   { Step.new([double]).map { raise exception } }
    let(:pending)   { Step.new([double]).map { raise Result::Pending.new("TODO") } }
    let(:undefined) { Step.new([double]) }
    let(:exception) { StandardError.new('test error') }

    context "reporting the duration of a test case" do
      before do
        time = double
        Time.stub(now: time)
        time.stub(:nsec).and_return(946752000, 946752001)
        time.stub(:to_i).and_return(1377009235, 1377009235)
      end

      context "for a passing test case" do
        let(:test_steps) { [passing] }

        it "records the nanoseconds duration of the execution on the result" do
          report.should_receive(:after_test_case) do |reported_test_case, result|
            result.duration.should eq(1)
          end
          test_case.describe_to runner
        end
      end

      context "for a failing test case" do
        let(:test_steps) { [failing] }

        it "records the duration" do
          report.should_receive(:after_test_case) do |reported_test_case, result|
            result.duration.should eq(1)
          end
          test_case.describe_to runner
        end
      end
    end

    context "reporting the exception that failed a test case" do
      let(:test_steps) { [failing] }
      it "sets the exception on the result" do
        report.should_receive(:after_test_case) do |reported_test_case, result|
          result.exception.should eq(exception)
        end
        test_case.describe_to runner
      end
    end

    context "with a single case" do
      context "without steps" do
        let(:test_steps) { [] }

        it "calls the report before running the case" do
          report.should_receive(:before_test_case).with(test_case)
          test_case.describe_to runner
        end

        it "calls the report after running the case" do
          report.should_receive(:after_test_case) do |reported_test_case, result|
            reported_test_case.should eq(test_case)
            result.should be_unknown
          end
          test_case.describe_to runner
        end
      end

      context 'with steps' do
        context 'that all pass' do
          let(:test_steps) { [ passing, passing ]  }

          it 'reports a passing test case' do
            report.should_receive(:after_test_case) do |test_case, result|
              result.should be_passed
            end
            test_case.describe_to runner
          end
        end

        context 'an undefined step' do
          let(:test_steps) { [ undefined ]  }

          it 'reports an undefined test case' do
            report.should_receive(:after_test_case) do |test_case, result|
              result.should be_undefined
            end
            test_case.describe_to runner
          end
        end

        context 'a pending step' do
          let(:test_steps) { [ pending ] }

          it 'reports a pending test case' do
            report.should_receive(:after_test_case) do |test_case, result|
              result.should be_pending
            end
            test_case.describe_to runner
          end
        end

        context 'that fail' do
          let(:test_steps) { [ failing ] }

          it 'reports a failing test case' do
            report.should_receive(:after_test_case) do |test_case, result|
              result.should be_failed
            end
            test_case.describe_to runner
          end
        end

        context 'where the first step fails' do
          let(:test_steps) { [ failing, passing ] }

          it 'reports the first step as failed' do
            report.should_receive(:after_test_step).with(failing, anything) do |test_step, result|
              result.should be_failed
            end
            test_case.describe_to runner
          end

          it 'reports the second step as skipped' do
            report.should_receive(:after_test_step).with(passing, anything) do |test_step, result|
              result.should be_skipped
            end
            test_case.describe_to runner
          end

          it 'reports the test case as failed' do
            report.should_receive(:after_test_case) do |test_case, result|
              result.should be_failed
              result.exception.should eq(exception)
            end
            test_case.describe_to runner
          end

          it 'skips, rather than executing the second step' do
            passing.should_not_receive(:execute)
            passing.should_receive(:skip)
            test_case.describe_to runner
          end
        end

      end
    end

    context 'with multiple test cases' do
      context 'when the first test case fails' do
        let(:first_test_case) { Case.new([failing], source) }
        let(:last_test_case)  { Case.new([passing], source) }
        let(:test_cases)      { [first_test_case, last_test_case] }

        it 'reports the results correctly for the following test case' do
          report.
            should_receive(:after_test_case).
            with(last_test_case, anything) do |reported_test_case, result|
            result.should be_passed
            end

          test_cases.each { |c| c.describe_to runner }
        end
      end
    end

  end

end
