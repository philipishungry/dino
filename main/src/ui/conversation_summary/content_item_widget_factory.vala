using Gee;
using Gdk;
using Gtk;
using Pango;
using Xmpp;
using Unicode;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

public class ContentItemWidgetFactory : Object {

    private StreamInteractor stream_interactor;
    private HashMap<string, WidgetGenerator> generators = new HashMap<string, WidgetGenerator>();

    public ContentItemWidgetFactory(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;

        generators[MessageItem.TYPE] = new MessageItemWidgetGenerator(stream_interactor);
        generators[FileItem.TYPE] = new FileItemWidgetGenerator(stream_interactor);
    }

    public Widget? get_widget(ContentItem item) {
        WidgetGenerator? generator = generators[item.type_];
        if (generator != null) {
            return (Widget?) generator.get_widget(item);
        }
        return null;
    }

    public void register_widget_generator(WidgetGenerator generator) {
        generators[generator.handles_type] = generator;
    }
}

public interface WidgetGenerator : Object {
    public abstract string handles_type { get; set; }
    public abstract Object get_widget(ContentItem item);
}

public class MessageItemWidgetGenerator : WidgetGenerator, Object {

    public string handles_type { get; set; default=FileItem.TYPE; }

    private StreamInteractor stream_interactor;

    public MessageItemWidgetGenerator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public Object get_widget(ContentItem item) {
        MessageItem message_item = item as MessageItem;
        Conversation conversation = message_item.conversation;
        Message message = message_item.message;

        Label label = new Label("") { use_markup=true, xalign=0, selectable=true, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, vexpand=true, visible=true };
        string markup_text = message.body;
        if (markup_text.length > 10000) {
            markup_text = markup_text.substring(0, 10000) + " [" + _("Message too long") + "]";
        }
        if (message_item.message.body.has_prefix("/me")) {
            markup_text = markup_text.substring(3);
        }

        if (conversation.type_ == Conversation.Type.GROUPCHAT) {
            markup_text = Util.parse_add_markup(markup_text, conversation.nickname, true, true);
        } else {
            markup_text = Util.parse_add_markup(markup_text, null, true, true);
        }

        if (message_item.message.body.has_prefix("/me")) {
            string display_name = Util.get_participant_display_name(stream_interactor, conversation, message.from);
            update_me_style(stream_interactor, message.real_jid ?? message.from, display_name, conversation.account, label, markup_text);
            label.realize.connect(() => update_me_style(stream_interactor, message.real_jid ?? message.from, display_name, conversation.account, label, markup_text));
            label.style_updated.connect(() => update_me_style(stream_interactor, message.real_jid ?? message.from, display_name, conversation.account, label, markup_text));
        }

        int only_emoji_count = Util.get_only_emoji_count(markup_text);
        if (only_emoji_count != -1) {
            string size_str = only_emoji_count < 5 ? "xx-large" : "large";
            markup_text = @"<span size=\'$size_str\'>" + markup_text + "</span>";
        }

        label.label = markup_text;

        Box box = new Box(Orientation.VERTICAL, 3) { visible=true };
        box.add(label);
        box.add(new ReactionsWidget(conversation, message, stream_interactor) { visible=true });

        return box;
    }

    public static void update_me_style(StreamInteractor stream_interactor, Jid jid, string display_name, Account account, Label label, string action_text) {
        string color = Util.get_name_hex_color(stream_interactor, account, jid, Util.is_dark_theme(label));
        label.label = @"<span color=\"#$(color)\">$(Markup.escape_text(display_name))</span>" + action_text;
    }
}

public class FileItemWidgetGenerator : WidgetGenerator, Object {

    public StreamInteractor stream_interactor;
    public string handles_type { get; set; default=FileItem.TYPE; }

    private const int MAX_HEIGHT = 300;
    private const int MAX_WIDTH = 600;

    public FileItemWidgetGenerator(StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
    }

    public Object get_widget(ContentItem item) {
        FileItem file_item = item as FileItem;
        FileTransfer transfer = file_item.file_transfer;

        return new FileWidget(stream_interactor, transfer) { visible=true };
    }
}

public class ReactionsWidget : Box {

    private Conversation conversation;
    private Account account;
    private Message message;
    private StreamInteractor stream_interactor;

    private HashMap<string, Label> reaction_counts = new HashMap<string, Label>();
    private HashMap<string, Button> reaction_buttons = new HashMap<string, Button>();
    private HashMap<string, Gee.List<Jid>> reactions = new HashMap<string, Gee.List<Jid>>();

    private Box reactions_box;
    private bool initialized = false;

    public ReactionsWidget(Conversation conversation, Message message, StreamInteractor stream_interactor) {
        this.conversation = conversation;
        this.account = conversation.account;
        this.message = message;
        this.stream_interactor = stream_interactor;

        HashMap<string, Gee.List<Jid>> reactions = stream_interactor.get_module(Reactions.IDENTITY).get_message_reactions(account, message);
        if (reactions.size > 0) {
            initialize();
        }
        foreach (string reaction in reactions.keys) {
            foreach (Jid jid in reactions[reaction]) {
                reaction_added(reaction, jid);
            }
        }

        stream_interactor.get_module(Reactions.IDENTITY).reaction_added.connect((account, message, jid, reaction) => {
            if (account.equals(this.account) && message.equals(this.message)) {
                reaction_added(reaction, jid);
            }
        });
        stream_interactor.get_module(Reactions.IDENTITY).reaction_removed.connect((account, message, jid, reaction) => {
            if (account.equals(this.account) && message.equals(this.message)) {
                reaction_removed(reaction, jid);
            }
        });
    }

    public void initialize() {
        reactions_box = new Box(Orientation.HORIZONTAL, 5) { visible=true };
        this.add(reactions_box);

        MenuButton add_button = new MenuButton() { tooltip_text= _("Add reaction"), visible=true };
        add_button.get_style_context().add_class("reaction-box");
        Image add_image = new Image.from_icon_name("dino-emoticon-add-symbolic", IconSize.SMALL_TOOLBAR) { margin_left=5, margin_right=5, visible=true };
        add_button.add(add_image);
        reactions_box.pack_end(add_button);

        EmojiChooser chooser = new EmojiChooser();
        chooser.emoji_picked.connect((emoji) => {
            stream_interactor.get_module(Reactions.IDENTITY).add_reaction(account, message, emoji);
        });
        add_button.set_popover(chooser);

        initialized = true;
    }

    public void reaction_added(string reaction, Jid jid) {
        if (!initialized) {
            initialize();
        }

        if (reactions.contains(reaction)) {
            reactions[reaction].add(jid);
            reaction_counts[reaction].label = "<span size='small'>" + reactions[reaction].size.to_string() + "</span>";
            if (jid.equals(account.bare_jid)) {
                reaction_buttons[reaction].get_style_context().add_class("own-reaction");
            }
        } else {
            reactions[reaction] = new ArrayList<Jid>(Jid.equals_func);
            reactions[reaction].add(jid);

            Label reaction_label = new Label("<span size='small'>" + reaction + "</span>") { use_markup=true, visible=true };
            Label count_label = new Label("<span size='small'>" + reactions[reaction].size.to_string() + "</span>") { use_markup=true, visible=true };

            Button button = new Button() { visible=true };
            button.get_style_context().add_class("reaction-box");
            Box reaction_box = new Box(Orientation.HORIZONTAL, 4) { visible=true };
            if (jid.equals(account.bare_jid)) {
                button.get_style_context().add_class("own-reaction");
            }
            reaction_box.add(reaction_label);
            reaction_box.add(count_label);

            button.add(reaction_box);
            reactions_box.add(button);

            button.clicked.connect(() => {
                if (reactions[reaction].contains(account.bare_jid)) {
                    stream_interactor.get_module(Reactions.IDENTITY).remove_reaction(account, message, reaction);
                } else {
                    stream_interactor.get_module(Reactions.IDENTITY).add_reaction(account, message, reaction);
                }
            });

            reaction_counts[reaction] = count_label;
            reaction_buttons[reaction] = button;
        }
        update_tooltip(reaction);
    }

    public void reaction_removed(string reaction, Jid jid) {
        if (!reactions.contains(reaction)) warning("wtf");

        reactions[reaction].remove(jid);

        if (reactions[reaction].size > 0) {
            reaction_counts[reaction].label = "<span size='small'>" + reactions[reaction].size.to_string() + "</span>";
            if (jid.equals(account.bare_jid)) {
                reaction_buttons[reaction].get_style_context().remove_class("own-reaction");
            }
            update_tooltip(reaction);
        } else {
            reaction_buttons[reaction].destroy();
            reactions.unset(reaction);
        }

        if (reactions.size == 0) {
            reactions_box.destroy();
            initialized = false;
        }
    }

    private void update_tooltip(string reaction) {
        if (reactions[reaction].size == 0) return;

        string tooltip_str = "";
        if (reactions[reaction].contains(account.bare_jid)) {
            tooltip_str += "You ";
        }
        foreach (Jid jid in reactions[reaction]) {
            if (jid.equals(account.bare_jid)) continue;

            tooltip_str += Util.get_participant_display_name(stream_interactor, conversation, jid) + " ";
        }
        tooltip_str += "reacted";

        reaction_buttons[reaction].set_tooltip_text(tooltip_str);
    }
}

}
