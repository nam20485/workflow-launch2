
import email
import html2text
import sys
import os

def convert_mhtml_to_markdown(mhtml_file_path):
    """
    Converts an MHTML file to a Markdown file.

    Args:
        mhtml_file_path (str): The path to the MHTML file.
    """
    try:
        with open(mhtml_file_path, 'r', encoding='utf-8') as f:
            msg = email.message_from_file(f)

        html_content = ""
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                if content_type == 'text/html':
                    html_content = part.get_payload(decode=True).decode(part.get_content_charset() or 'utf-8')
                    break
        else:
            if msg.get_content_type() == 'text/html':
                html_content = msg.get_payload(decode=True).decode(msg.get_content_charset() or 'utf-8')

        if not html_content:
            print(f"No HTML content found in {mhtml_file_path}")
            return

        h = html2text.HTML2Text()
        h.ignore_links = False
        h.ignore_images = False
        markdown = h.handle(html_content)

        file_name, _ = os.path.splitext(mhtml_file_path)
        markdown_file_path = file_name + '.md'

        with open(markdown_file_path, 'w', encoding='utf-8') as f:
            f.write(markdown)

        print(f"Successfully converted {mhtml_file_path} to {markdown_file_path}")

    except Exception as e:
        print(f"An error occurred while processing {mhtml_file_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python convert_mhtml.py <file1.mhtml> <file2.mhtml> ...")
        sys.exit(1)

    for file_path in sys.argv[1:]:
        convert_mhtml_to_markdown(file_path)
