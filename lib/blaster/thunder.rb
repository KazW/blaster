require 'libusb'

module Blaster
  class Thunder
    LED_ON     = [0x03, 0x01].pack('CC')
    LED_OFF    = [0x03, 0x00].pack('CC')

    MOVE_UP    = [0x02, 0x02].pack('CC')
    MOVE_DOWN  = [0x02, 0x03].pack('CC')
    MOVE_LEFT  = [0x02, 0x04].pack('CC')
    MOVE_RIGHT = [0x02, 0x08].pack('CC')
    STOP_MOVE  = [0x02, 0x20].pack('CC')

    FIRE       = [0x02, 0x10].pack('CC')

    attr_accessor :horizontal_degree_second, :vertical_degree_second,
                  :blink_duration, :blink_pause, :monitor_pause, :firing_pause

    def initialize(do_blink = false, do_monitor = false, horizontal_move_rate = 5.5, vertical_move_rate = 0.5)
      @usb_context = LIBUSB::Context.new
      @device = @usb_context.devices(idVendor: 0x2123, idProduct: 0x1010).first
      @handle = @device.open
      @horizontal_degree_second = horizontal_move_rate / 270
      @vertical_degree_second = vertical_move_rate / 55
      blink_mode do_blink
      monitor_mode do_monitor
    end

    def deactivate
      stop_monitoring
      stop_blinking
      @handle = @handle.close
    end

    def send_raw(command)
      return if command.nil? || !command.is_a?(String)
      @handle.control_transfer bmRequestType: 0x21, bRequest: 0x09,
                               wValue: 0, wIndex: 0, dataOut: command
    end

    def move_then_stop(command, duration)
      return if command.nil? || duration.nil? || !duration.is_a?(Numeric)
      return if @firing
      send_raw command
      sleep duration
      send_raw STOP_MOVE
    end

    def move_degrees(command, degrees)
      if command == MOVE_LEFT || command == MOVE_RIGHT
        move_then_stop command, degrees * @horizontal_degree_second
      else
        move_then_stop command, degrees * @vertical_degree_second
      end
    end

    def fire!
      @firing = true
      @firing_pause ||= 5
      send_raw FIRE
      sleep @firing_pause
      @firing = false
    end

    def blink(duration = 1)
      return if @blink_loop
      return if !duration.is_a?(Numeric)
      send_raw LED_ON
      sleep duration
      send_raw LED_OFF
    end

    def led_on
      send_raw LED_ON
    end

    def led_off
      send_raw LED_OFF
    end

    def up(degrees = 10)
      move_degrees MOVE_UP, degrees
    end

    def down(degrees = 10)
      move_degrees MOVE_DOWN, degrees
    end

    def left(degrees = 10)
      move_degrees MOVE_LEFT, degrees
    end

    def right(degrees = 10)
      move_degrees MOVE_RIGHT, degrees
    end

    def stop
      send_raw STOP_MOVE
    end

    def full_up
      send_raw MOVE_UP
    end

    def full_down
      send_raw MOVE_DOWN
    end

    def full_left
      send_raw MOVE_LEFT
    end

    def full_right
      send_raw MOVE_RIGHT
    end

    def blink_mode(do_blink)
      if do_blink && !@blink_loop
        @blink_loop = true
        @blink_duration ||= 0.001
        @blink_pause ||= 0.5
        @blink_thread = Thread.new{ start_blinking() }
      else
        stop_blinking
      end
    end

    def monitor_mode(do_monitor)
      if do_monitor && !@monitor_loop
        @monitor_loop = true
        @monitor_pause ||= 10
        @monitor_thread = Thread.new{ start_monitoring() }
      else
        stop_monitoring
      end
    end

private

      def start_blinking
        while @blink_loop
          led_on
          sleep @blink_duration
          led_off
          sleep @blink_pause
        end
      end

      def stop_blinking
        @blink_loop = false
        @blink_thread.kill if !@blink_thread.nil? && @blink_thread.alive?
        @blink_thread = nil
      end

      def start_monitoring
        while @monitor_loop
          full_right unless @firing
          sleep @monitor_pause
          full_down unless @firing
          sleep 2
          full_left unless @firing
          sleep @monitor_pause
          full_up unless @firing
          sleep 2
        end
      end

      def stop_monitoring
        @monitor_loop = false
        @monitor_thread.kill if !@monitor_thread.nil? && @monitor_thread.alive?
        @monitor_thread = nil
      end
  end
end